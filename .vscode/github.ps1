$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send($obj) {
    [Console]::Out.WriteLine(($obj | ConvertTo-Json -Depth 10 -Compress))
    [Console]::Out.Flush()
}

function Get-GitHubRepo([string]$owner, [string]$repo) {
    if ($owner -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$') { throw "Invalid owner: $owner" }
    if ($repo -notmatch '^[A-Za-z0-9._-]{1,100}$') { throw "Invalid repo: $repo" }
    $headers = @{ 'User-Agent' = 'mcp-github-windows'; 'Accept' = 'application/vnd.github+json' }
    if ($env:GITHUB_TOKEN) { $headers['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }
    $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo" -Headers $headers -TimeoutSec 20
    [ordered]@{
        full_name   = $r.full_name
        description = $r.description
        language    = $r.language
        stars       = $r.stargazers_count
        forks       = $r.forks_count
        open_issues = $r.open_issues_count
        html_url    = $r.html_url
    } | ConvertTo-Json -Compress
}

while ($null -ne ($line = [Console]::In.ReadLine())) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try { $msg = $line | ConvertFrom-Json } catch { continue }
    if ($null -eq $msg.id) { continue }  # notifications need no response

    switch ($msg.method) {
        'initialize' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    protocolVersion = $msg.params.protocolVersion
                    capabilities    = @{ tools = @{} }
                    serverInfo      = @{ name = 'github-windows'; version = '1.0.0' }
                }
            }
        }
        'tools/list' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    tools = @(
                        @{
                            name        = 'get_repo'
                            description = 'Returns basic information about a GitHub repository.'
                            inputSchema = @{
                                type       = 'object'
                                properties = @{
                                    owner = @{ type = 'string'; description = 'Repository owner (user or organization)' }
                                    repo  = @{ type = 'string'; description = 'Repository name' }
                                }
                                required   = @('owner', 'repo')
                            }
                        }
                    )
                }
            }
        }
        'tools/call' {
            if ($msg.params.name -eq 'get_repo') {
                try {
                    $a = $msg.params.arguments
                    $text = Get-GitHubRepo $a.owner $a.repo
                    Send @{
                        jsonrpc = '2.0'; id = $msg.id
                        result = @{ content = @(@{ type = 'text'; text = $text }) }
                    }
                } catch {
                    Send @{
                        jsonrpc = '2.0'; id = $msg.id
                        result = @{ isError = $true; content = @(@{ type = 'text'; text = $_.Exception.Message }) }
                    }
                }
            } else {
                Send @{ jsonrpc = '2.0'; id = $msg.id; error = @{ code = -32602; message = "Unknown tool: $($msg.params.name)" } }
            }
        }
        'ping' { Send @{ jsonrpc = '2.0'; id = $msg.id; result = @{} } }
        default { Send @{ jsonrpc = '2.0'; id = $msg.id; error = @{ code = -32601; message = "Method not found: $($msg.method)" } } }
    }
}
