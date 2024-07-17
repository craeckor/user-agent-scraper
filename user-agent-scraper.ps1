[CmdletBinding()] param ()
$useragent = '-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.5" -H "Cache-Control: no-cache"'
$devicesite = "https://explore.whatismybrowser.com/useragents/explore/operating_platform_string/"
$listhashurl = "https://raw.githubusercontent.com/craeckor/user-agent-scraper/main/curl-user-agents.txt.sha256"
$listurl = "https://raw.githubusercontent.com/craeckor/user-agent-scraper/main/curl-user-agents.txt"
$listhash = $(curl.exe -s -L $listhashurl)
if (Test-Path .\curl-user-agents.txt) {
    $listhashfile = Get-FileHash -Algorithm SHA256 -Path .\curl-user-agents.txt
    if (!($listhashfile.Hash -eq $listhash)) {
        Remove-Item -Force .\curl-user-agents.txt
        curl.exe -s -L $listurl -o .\curl-user-agents.txt
    }
} else {
    curl.exe -s -L $listurl -o .\curl-user-agents.txt
}
$curlagentlist = Get-Content -Path .\curl-user-agents.txt
if (Test-Path .\device-links.txt) {
    Remove-Item -Force .\device-links.txt
}
if (Test-Path .\scraped-user-agents.txt) {
    $lastmodtime = (get-item .\scraped-user-agents.txt).LastWriteTime
    $lastmodtimemod = $lastmodtime.ToString("yyyy-MM-dd_HH-mm-ss")
    if (!(Test-Path .\scraped-user-agents)) {
        New-Item -Path .\ -Name "scraped-user-agents" -ItemType "directory"
    }
    Move-Item -Path .\scraped-user-agents.txt -Destination .\scraped-user-agents\scraped-user-agents_$lastmodtimemod.txt -Force
}
$block = $true
$counter = 0
while ($block) {
    $counter++
    $devicedownload = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 30 -s -L $devicesite)
    if (!(($devicedownload -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
        $block = $false
    } else {
        Write-Verbose "blocked"
    }
    if ($devicedownload -match "</html>") {
        $block = $false
    } else {
        $block = $true
        Write-Verbose "End is missing"
    }
}
if (!($counter -eq 1)) {
    Write-Verbose "$devicesite --> $counter tries"
} else {
    Write-Verbose "$devicesite --> $counter try"
}
$deviceexport = $($devicedownload | ConvertFrom-String -Delimiter '<td><a href=' | Select-Object -ExpandProperty P2 | ConvertFrom-String -Delimiter '"' | Select-Object -ExpandProperty P2)
$deviceexport > .\device-links.txt
$devicelist = Get-Content -Path .\device-links.txt
foreach ($link in $devicelist) {
    $block = $true
    $counter = 0
    while ($block) {
        $counter++
        $sitedownload = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 10 -s -L $link)
        if (!(($sitedownload -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
            $block = $false
        } else {
            Write-Verbose "blocked"
        }
        if ($sitedownload -match "</html>") {
            $block = $false
        } else {
            $block = $true
            Write-Verbose "End is missing"
        }
    }
    if (!($counter -eq 1)) {
        Write-Verbose "$link --> $counter tries"
    } else {
        Write-Verbose "$link --> $counter try"
    }
    $listextracted = $($sitedownload | ConvertFrom-String -Delimiter 'Last Page' | Select-Object -ExpandProperty P2 | ConvertFrom-String -Delimiter ' ' | Select-Object -ExpandProperty P2)
    $sitelist = $($listextracted -replace '\((\d+)\)</a>', '$1')
    $list = 1..$sitelist
    if ($listextracted -eq $null) {
        $list = 1
    }
    Write-Verbose "List: $list"
    foreach ($site in $list) {
        $block = $true
        $counter = 0
        while ($block) {
            $counter++
            $download = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 10 -s -L $link$site)
            if (!(($download -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
                $block = $false
            } else {
                Write-Verbose "blocked"
            }
            if ($download -match "</html>") {
                $block = $false
            } else {
                $block = $true
                Write-Verbose "End is missing"
            }
        }
        if (!($counter -eq 1)) {
            Write-Verbose "$link$site --> $counter tries"
        } else {
            Write-Verbose "$link$site --> $counter try"
        }
        $downloadextracted = $($download | ConvertFrom-String -Delimiter '<td>' | Select-Object P2 | ConvertFrom-String -Delimiter '"' | Select-Object P5 | ConvertFrom-String -Delimiter '>' | Select-Object -ExpandProperty P2)
        $agents = $($downloadextracted -replace '</a', '')
        $agents >> .\scraped-user-agents.txt
    }
}