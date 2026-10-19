$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send($obj) {
    [Console]::Out.WriteLine(($obj | ConvertTo-Json -Depth 10 -Compress))
    [Console]::Out.Flush()
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
                    serverInfo      = @{ name = 'get-time-windows'; version = '1.0.0' }
                }
            }
        }
        'tools/list' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    tools = @(
                        @{
                            name        = 'get_time'
                            description = 'Returns the current date and time, optionally in a given time zone.'
                            inputSchema = @{
                                type       = 'object'
                                properties = @{ timezone = @{ type = 'string'; description = 'Windows time zone ID, e.g. "India Standard Time". Defaults to local time.' } }
                            }
                        }
                    )
                }
            }
        }
        'tools/call' {
            if ($msg.params.name -eq 'get_time') {
                try {
                    $tzId = $msg.params.arguments.timezone
                    if ([string]::IsNullOrWhiteSpace($tzId)) {
                        $now = Get-Date
                    } else {
                        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($tzId)
                        $now = [System.TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $tz)
                    }
                    Send @{
                        jsonrpc = '2.0'; id = $msg.id
                        result = @{ content = @(@{ type = 'text'; text = $now.ToString('yyyy-MM-dd HH:mm:ss zzz') }) }
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
