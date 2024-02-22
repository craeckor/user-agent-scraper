$curlagentlist = Get-Content -Path .\curl-user-agents.txt
$useragent = '-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.5" -H "Cache-Control: no-cache"'
$devicesite = "https://explore.whatismybrowser.com/useragents/explore/operating_platform_string/"
if (Test-Path .\device-links.txt) {
    Remove-Item -Force .\device-links.txt
}
if (Test-Path .\scraped-user-agents.txt) {
    Remove-Item -Force .\scraped-user-agents.txt
}
$block = $true
while ($block) {
    $devicedownload = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 30 -s -L $devicesite)
    if (!(($devicedownload -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
        $block = $false
    }
    if (!($devicedownload -eq "")) {
        $block = $false
    } else {
        $block = $true
    }
    if ($devicedownload -match "</html>") {
        $block = $false
    } else {
        $block = $true
    }
}
$deviceexport = $($devicedownload | ConvertFrom-String -Delimiter '<td><a href=' | Select-Object -ExpandProperty P2 | ConvertFrom-String -Delimiter '"' | Select-Object -ExpandProperty P2)
$deviceexport > .\device-links.txt
$devicelist = Get-Content -Path .\device-links.txt
foreach ($link in $devicelist) {
    $block = $true
    while ($block) {
        $sitedownload = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 10 -s -L $link)
        if (!(($devicedownload -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
            $block = $false
        }
        if (!($devicedownload -eq "")) {
            $block = $false
        } else {
            $block = $true
        }
        if ($devicedownload -match "</html>") {
            $block = $false
        } else {
            $block = $true
        }
    }
    $listextracted = $($sitedownload | ConvertFrom-String -Delimiter 'Last Page' | Select-Object -ExpandProperty P2 | ConvertFrom-String -Delimiter ' ' | Select-Object -ExpandProperty P2)
    $sitelist = $($listextracted -replace '\((\d+)\)</a>', '$1')
    $list = 1..$sitelist
    foreach ($site in $list) {
        $block = $true
        while ($block) {
            $download = $(curl.exe $useragent -H "User-Agent: $($curlagentlist | Get-Random)" -x socks5://127.0.0.1:9050 --max-time 10 -s -L $link$site)
            if (!(($devicedownload -match "You have been blocked") -or ($devicedownload -match "Your IP address range has been blocked"))) {
                $block = $false
            }
            if (!($devicedownload -eq "")) {
                $block = $false
            } else {
                $block = $true
            }
            if ($devicedownload -match "</html>") {
                $block = $false
            } else {
                $block = $true
            }
        }
        $downloadextracted = $($download | ConvertFrom-String -Delimiter '<td>' | Select-Object P2 | ConvertFrom-String -Delimiter '"' | Select-Object P5 | ConvertFrom-String -Delimiter '>' | Select-Object -ExpandProperty P2)
        $agents = $($downloadextracted -replace '</a', '')
        $agents >> .\scraped-user-agents.txt
    }
}