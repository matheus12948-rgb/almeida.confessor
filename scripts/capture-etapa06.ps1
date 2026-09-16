$port = 9222
$chrome = Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList "--headless=new", "--remote-debugging-port=$port", "--disable-gpu", "http://localhost:5500" -PassThru

Start-Sleep -Seconds 2

try {
    $pages = Invoke-RestMethod -Uri "http://localhost:$port/json"
    $targetPage = $pages | Where-Object { $_.type -eq "page" -and $_.url -like "*5500*" } | Select-Object -First 1
    if (-not $targetPage) {
        $targetPage = $pages | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    }

    $wsUrl = $targetPage.webSocketDebuggerUrl
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $cts = New-Object System.Threading.CancellationTokenSource
    $ws.ConnectAsync([System.Uri]$wsUrl, $cts.Token).Wait()

    $msgId = 1
    function Call-CDP($method, $params) {
        $id = $script:msgId++
        $payload = @{ id = $id; method = $method; params = $params } | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $buffer = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $receiveBuffer = New-Object byte[] 8388608
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$receiveBuffer)

        while ($true) {
            $sb = New-Object System.Text.StringBuilder
            do {
                $res = $ws.ReceiveAsync($segment, $cts.Token).Result
                $chunk = [System.Text.Encoding]::UTF8.GetString($receiveBuffer, 0, $res.Count)
                [void]$sb.Append($chunk)
            } while (-not $res.EndOfMessage)

            $jsonStr = $sb.ToString()
            $obj = $jsonStr | ConvertFrom-Json
            if ($obj.id -eq $id) {
                return $obj
            }
        }
    }

    # 1. Desktop Fullpage Capture (1440px)
    [void](Call-CDP "Emulation.setDeviceMetricsOverride" @{
        width = 1440
        height = 900
        deviceScaleFactor = 1
        mobile = $false
    })
    [void](Call-CDP "Runtime.evaluate" @{ expression = "window.scrollTo(0, document.body.scrollHeight)" })
    Start-Sleep -Milliseconds 800
    [void](Call-CDP "Runtime.evaluate" @{ expression = "window.scrollTo(0, 0)" })
    Start-Sleep -Milliseconds 400

    $respDesk = Call-CDP "Page.captureScreenshot" @{
        format = "png"
        captureBeyondViewport = $true
    }
    if ($respDesk.result.data) {
        $bytes = [System.Convert]::FromBase64String($respDesk.result.data)
        [System.IO.File]::WriteAllBytes("$PWD\preview-etapa06-desktop.png", $bytes)
        Write-Output "SUCCESS: Desktop ($($bytes.Length) bytes) saved"
    }

    # 2. Desktop Section-Specific View
    [void](Call-CDP "Runtime.evaluate" @{ expression = "document.getElementById('contato').scrollIntoView({behavior: 'instant', block: 'center'})" })
    Start-Sleep -Milliseconds 600
    $respSec = Call-CDP "Page.captureScreenshot" @{
        format = "png"
        captureBeyondViewport = $false
    }
    if ($respSec.result.data) {
        $bytesSec = [System.Convert]::FromBase64String($respSec.result.data)
        [System.IO.File]::WriteAllBytes("$PWD\preview-etapa06-section.png", $bytesSec)
        Write-Output "SUCCESS: Section View ($($bytesSec.Length) bytes) saved"
    }

    # 3. Mobile Fullpage Capture (390px)
    [void](Call-CDP "Emulation.setDeviceMetricsOverride" @{
        width = 390
        height = 844
        deviceScaleFactor = 2
        mobile = $true
    })
    [void](Call-CDP "Runtime.evaluate" @{ expression = "window.scrollTo(0, document.body.scrollHeight)" })
    Start-Sleep -Milliseconds 800
    [void](Call-CDP "Runtime.evaluate" @{ expression = "window.scrollTo(0, 0)" })
    Start-Sleep -Milliseconds 400

    $respMob = Call-CDP "Page.captureScreenshot" @{
        format = "png"
        captureBeyondViewport = $true
    }
    if ($respMob.result.data) {
        $bytes = [System.Convert]::FromBase64String($respMob.result.data)
        [System.IO.File]::WriteAllBytes("$PWD\preview-etapa06-mobile.png", $bytes)
        Write-Output "SUCCESS: Mobile ($($bytes.Length) bytes) saved"
    }

    # 4. Mobile Section-Specific View
    [void](Call-CDP "Runtime.evaluate" @{ expression = "document.getElementById('contato').scrollIntoView({behavior: 'instant', block: 'center'})" })
    Start-Sleep -Milliseconds 600
    $respMobSec = Call-CDP "Page.captureScreenshot" @{
        format = "png"
        captureBeyondViewport = $false
    }
    if ($respMobSec.result.data) {
        $bytesMobSec = [System.Convert]::FromBase64String($respMobSec.result.data)
        [System.IO.File]::WriteAllBytes("$PWD\preview-etapa06-mobile-section.png", $bytesMobSec)
        Write-Output "SUCCESS: Mobile Section View ($($bytesMobSec.Length) bytes) saved"
    }

    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
} finally {
    if ($chrome -and -not $chrome.HasExited) {
        Stop-Process -Id $chrome.Id -Force
    }
}
