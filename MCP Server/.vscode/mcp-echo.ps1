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
                    serverInfo      = @{ name = 'echo-windows'; version = '1.0.0' }
                }
            }
        }
        'tools/list' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    tools = @(
                        @{
                            name        = 'echo'
                            description = 'Echoes back the provided message.'
                            inputSchema = @{
                                type       = 'object'
                                properties = @{ message = @{ type = 'string'; description = 'Message to echo' } }
                                required   = @('message')
                            }
                        }
                    )
                }
            }
        }
        'tools/call' {
            if ($msg.params.name -eq 'echo') {
                Send @{
                    jsonrpc = '2.0'; id = $msg.id
                    result = @{ content = @(@{ type = 'text'; text = [string]$msg.params.arguments.message }) }
                }
            } else {
                Send @{ jsonrpc = '2.0'; id = $msg.id; error = @{ code = -32602; message = "Unknown tool: $($msg.params.name)" } }
            }
        }
        'ping' { Send @{ jsonrpc = '2.0'; id = $msg.id; result = @{} } }
        default { Send @{ jsonrpc = '2.0'; id = $msg.id; error = @{ code = -32601; message = "Method not found: $($msg.method)" } } }
    }
}
