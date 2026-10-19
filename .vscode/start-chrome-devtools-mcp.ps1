$ErrorActionPreference = "Stop"

$chromePath = Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"
if (-not (Test-Path -LiteralPath $chromePath -PathType Leaf)) {
    throw "Google Chrome was not found at '$chromePath'."
}

$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npx) {
    throw "npx.cmd was not found. Install Node.js and ensure it is on PATH."
}

$debuggingUrl = "http://127.0.0.1:9222"
$versionEndpoint = "$debuggingUrl/json/version"
$browserVersion = $null

try {
    $browserVersion = Invoke-RestMethod -Uri $versionEndpoint -TimeoutSec 2
}
catch {
    $profilePath = Join-Path $env:LOCALAPPDATA "ChromeDevToolsMcp\chrome-profile"
    New-Item -ItemType Directory -Path $profilePath -Force | Out-Null

    Start-Process -FilePath $chromePath -ArgumentList @(
        "--remote-debugging-port=9222",
        "--user-data-dir=`"$profilePath`"",
        "--no-first-run",
        "--no-default-browser-check"
    ) | Out-Null

    $deadline = (Get-Date).AddSeconds(15)
    while (-not $browserVersion -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        try {
            $browserVersion = Invoke-RestMethod -Uri $versionEndpoint -TimeoutSec 2
        }
        catch {
            $browserVersion = $null
        }
    }
}

if (-not $browserVersion) {
    throw "Chrome did not expose its DevTools endpoint at $versionEndpoint within 15 seconds."
}

& $npx.Source -y chrome-devtools-mcp@latest "--browser-url=$debuggingUrl" --no-usage-statistics
exit $LASTEXITCODE
