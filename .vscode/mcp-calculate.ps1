$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send($obj) {
    [Console]::Out.WriteLine(($obj | ConvertTo-Json -Depth 10 -Compress))
    [Console]::Out.Flush()
}

function Invoke-Calc($op, [double]$a, [double]$b) {
    switch ($op) {
        'add'      { $a + $b }
        'subtract' { $a - $b }
        'multiply' { $a * $b }
        'divide'   { if ($b -eq 0) { throw 'Division by zero' }; $a / $b }
        default    { throw "Unknown operation: $op" }
    }
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
                    serverInfo      = @{ name = 'calculate-windows'; version = '1.0.0' }
                }
            }
        }
        'tools/list' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    tools = @(
                        @{
                            name        = 'calculate'
                            description = 'Performs basic arithmetic on two numbers.'
                            inputSchema = @{
                                type       = 'object'
                                properties = @{
                                    operation = @{ type = 'string'; enum = @('add', 'subtract', 'multiply', 'divide'); description = 'Arithmetic operation' }
                                    a         = @{ type = 'number'; description = 'First operand' }
                                    b         = @{ type = 'number'; description = 'Second operand' }
                                }
                                required   = @('operation', 'a', 'b')
                            }
                        }
                    )
                }
            }
        }
        'tools/call' {
            if ($msg.params.name -eq 'calculate') {
                try {
                    $args_ = $msg.params.arguments
                    $value = Invoke-Calc $args_.operation $args_.a $args_.b
                    Send @{
                        jsonrpc = '2.0'; id = $msg.id
                        result = @{ content = @(@{ type = 'text'; text = [string]$value }) }
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
