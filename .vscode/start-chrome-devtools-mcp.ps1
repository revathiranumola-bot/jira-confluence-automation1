$ErrorActionPreference = "Stop"

$chromePath = Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"
if (-not (Test-Path -LiteralPath $chromePath -PathType Leaf)) {
    throw "Google Chrome was not found at '$chromePath'."
}

$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npx) {
    throw "npx.cmd was not found. Install Node.js and ensure it is on PATH."
}

$profilePath = Join-Path $env:LOCALAPPDATA "ChromeDevToolsMcp\all-tools-profile"
$workspacePath = Split-Path -Parent $PSScriptRoot
$serverArgs = @(
    "-y",
    "chrome-devtools-mcp@latest",
    "--executablePath=$chromePath",
    "--userDataDir=$profilePath",
    "--workspace=$workspacePath",
    "--chromeArg=--enable-features=WebMCP",
    "--categoryInput=true",
    "--categoryNavigation=true",
    "--categoryEmulation=true",
    "--categoryPerformance=true",
    "--categoryNetwork=true",
    "--categoryDebugging=true",
    "--javascriptEvaluation=true",
    "--categoryMemory=true",
    "--categoryExtensions=true",
    "--categoryExperimentalThirdParty=true",
    "--categoryExperimentalWebmcp=true",
    "--categoryPwa=true",
    "--memoryDebugging=true",
    "--experimentalDevtools=true",
    "--experimentalVision=true",
    "--experimentalIncludeAllPages=true",
    "--slim=false",
    "--no-performance-crux",
    "--no-usage-statistics"
)

& $npx.Source @serverArgs
exit $LASTEXITCODE
