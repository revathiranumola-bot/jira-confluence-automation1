$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send($obj) {
    [Console]::Out.WriteLine(($obj | ConvertTo-Json -Depth 20 -Compress))
    [Console]::Out.Flush()
}

function Get-GitHubHeaders([bool]$RequireToken) {
    $headers = @{
        'User-Agent' = 'mcp-github-windows'
        'Accept'     = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
    } elseif ($RequireToken) {
        throw 'GITHUB_TOKEN is required. Configure the githubToken input in .vscode/mcp.json with a token that can manage repository issues.'
    }
    return $headers
}

function Invoke-GitHubApi([string]$Method, [string]$Path, $Body = $null, [bool]$RequireToken = $false) {
    $request = @{
        Method      = $Method
        Uri         = "https://api.github.com$Path"
        Headers     = Get-GitHubHeaders $RequireToken
        TimeoutSec  = 30
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $json = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
        $request['Body'] = [System.Text.Encoding]::UTF8.GetBytes($json)
        $request['ContentType'] = 'application/json; charset=utf-8'
    }
    try {
        return Invoke-RestMethod @request
    } catch {
        $message = $_.ErrorDetails.Message
        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = $_.Exception.Message
        }
        throw "GitHub API request failed: $message"
    }
}

function Assert-RepositoryName([string]$Owner, [string]$Repo) {
    if ($Owner -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$') {
        throw "Invalid owner: $Owner"
    }
    if ($Repo -notmatch '^[A-Za-z0-9._-]{1,100}$') {
        throw "Invalid repository name: $Repo"
    }
}

function Assert-IssueNumber([long]$IssueNumber) {
    if ($IssueNumber -lt 1) {
        throw 'issue_number must be a positive integer.'
    }
}

function Get-IssueSummary($Issue) {
    $labels = @($Issue.labels | ForEach-Object { $_.name })
    return [ordered]@{
        number   = $Issue.number
        title    = $Issue.title
        state    = $Issue.state
        body     = $Issue.body
        labels   = $labels
        html_url = $Issue.html_url
    }
}

function Get-GitHubRepo([string]$Owner, [string]$Repo) {
    Assert-RepositoryName $Owner $Repo
    $r = Invoke-GitHubApi 'GET' "/repos/$Owner/$Repo"
    return [ordered]@{
        full_name   = $r.full_name
        description = $r.description
        language    = $r.language
        stars       = $r.stargazers_count
        forks       = $r.forks_count
        open_issues = $r.open_issues_count
        html_url    = $r.html_url
    }
}

function New-GitHubIssue($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    if ([string]::IsNullOrWhiteSpace($Arguments.title)) {
        throw 'title is required and must not be blank.'
    }
    if ($Arguments.title.Length -gt 256) {
        throw 'title must be 256 characters or fewer.'
    }
    $payload = [ordered]@{ title = $Arguments.title }
    if ($Arguments.PSObject.Properties.Name -contains 'body') {
        if ($null -ne $Arguments.body -and $Arguments.body -isnot [string]) {
            throw 'body must be a string.'
        }
        $payload['body'] = $Arguments.body
    }
    if ($Arguments.PSObject.Properties.Name -contains 'labels') {
        $labels = @($Arguments.labels)
        if ($labels.Count -eq 0 -or @($labels | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
            throw 'labels must contain one or more non-empty strings.'
        }
        $payload['labels'] = $labels
    }
    $issue = Invoke-GitHubApi 'POST' "/repos/$($Arguments.owner)/$($Arguments.repo)/issues" $payload $true
    return Get-IssueSummary $issue
}

function Set-GitHubIssue($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    Assert-IssueNumber $Arguments.issue_number
    $provided = @($Arguments.PSObject.Properties.Name)
    $payload = [ordered]@{}

    if ($provided -contains 'title') {
        if ([string]::IsNullOrWhiteSpace($Arguments.title)) {
            throw 'title must not be blank.'
        }
        if ($Arguments.title.Length -gt 256) {
            throw 'title must be 256 characters or fewer.'
        }
        $payload['title'] = $Arguments.title
    }
    if ($provided -contains 'body') {
        if ($null -ne $Arguments.body -and $Arguments.body -isnot [string]) {
            throw 'body must be a string.'
        }
        $payload['body'] = $Arguments.body
    }
    if ($provided -contains 'state') {
        if ($Arguments.state -notin @('open', 'closed')) {
            throw "state must be 'open' or 'closed'."
        }
        $payload['state'] = $Arguments.state
    }
    if ($provided -contains 'state_reason') {
        if ($provided -notcontains 'state') {
            throw 'state_reason can only be provided together with state.'
        }
        if ($Arguments.state_reason -notin @('completed', 'not_planned', 'reopened')) {
            throw "state_reason must be 'completed', 'not_planned', or 'reopened'."
        }
        $payload['state_reason'] = $Arguments.state_reason
    }
    if ($payload.Count -eq 0) {
        throw 'Provide at least one field to update: title, body, or state.'
    }

    $issue = Invoke-GitHubApi 'PATCH' "/repos/$($Arguments.owner)/$($Arguments.repo)/issues/$($Arguments.issue_number)" $payload $true
    return Get-IssueSummary $issue
}

function Add-GitHubIssueLabels($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    Assert-IssueNumber $Arguments.issue_number
    $labels = @($Arguments.labels)
    if ($labels.Count -eq 0 -or @($labels | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
        throw 'labels must contain one or more non-empty strings.'
    }
    $result = Invoke-GitHubApi 'POST' "/repos/$($Arguments.owner)/$($Arguments.repo)/issues/$($Arguments.issue_number)/labels" @{ labels = $labels } $true
    return [ordered]@{
        issue_number = $Arguments.issue_number
        labels       = @($result | ForEach-Object { $_.name })
    }
}

function Remove-GitHubIssueLabels($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    Assert-IssueNumber $Arguments.issue_number
    $labels = @($Arguments.labels)
    if ($labels.Count -eq 0 -or @($labels | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
        throw 'labels must contain one or more non-empty strings.'
    }
    foreach ($label in $labels) {
        $encodedLabel = [System.Uri]::EscapeDataString($label)
        Invoke-GitHubApi 'DELETE' "/repos/$($Arguments.owner)/$($Arguments.repo)/issues/$($Arguments.issue_number)/labels/$encodedLabel" $null $true | Out-Null
    }
    return [ordered]@{
        issue_number = $Arguments.issue_number
        removed      = $labels
    }
}

function New-GitHubLabel($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    if ([string]::IsNullOrWhiteSpace($Arguments.name)) {
        throw 'name is required and must not be blank.'
    }
    if ($Arguments.name.Length -gt 50) {
        throw 'name must be 50 characters or fewer.'
    }
    $color = 'ededed'
    if ($Arguments.PSObject.Properties.Name -contains 'color') {
        $color = [string]$Arguments.color
    }
    if ($color -notmatch '^[A-Fa-f0-9]{6}$') {
        throw 'color must be a six-character hexadecimal color without #.'
    }
    $payload = [ordered]@{ name = $Arguments.name; color = $color }
    if ($Arguments.PSObject.Properties.Name -contains 'description') {
        if ($null -ne $Arguments.description -and $Arguments.description -isnot [string]) {
            throw 'description must be a string.'
        }
        $payload['description'] = $Arguments.description
    }
    $label = Invoke-GitHubApi 'POST' "/repos/$($Arguments.owner)/$($Arguments.repo)/labels" $payload $true
    return [ordered]@{
        name        = $label.name
        color       = $label.color
        description = $label.description
    }
}

function Add-GitHubIssueComment($Arguments) {
    Assert-RepositoryName $Arguments.owner $Arguments.repo
    Assert-IssueNumber $Arguments.issue_number
    if ([string]::IsNullOrWhiteSpace($Arguments.body)) {
        throw 'body is required and must not be blank.'
    }
    if ($Arguments.body.Length -gt 65536) {
        throw 'body must be 65536 characters or fewer.'
    }
    $comment = Invoke-GitHubApi 'POST' "/repos/$($Arguments.owner)/$($Arguments.repo)/issues/$($Arguments.issue_number)/comments" @{ body = $Arguments.body } $true
    return [ordered]@{
        issue_number = $Arguments.issue_number
        comment_id   = $comment.id
        body         = $comment.body
        html_url     = $comment.html_url
    }
}

$tools = @(
    @{
        name = 'get_repo'
        description = 'Returns basic information about a GitHub repository.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo  = @{ type = 'string'; description = 'Repository name.' }
            }
            required = @('owner', 'repo')
        }
    },
    @{
        name = 'create_issue'
        description = 'Creates a GitHub issue, optionally with a body and labels.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner  = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo   = @{ type = 'string'; description = 'Repository name.' }
                title  = @{ type = 'string'; description = 'Issue title (1-256 characters).' }
                body   = @{ type = 'string'; description = 'Optional issue description in Markdown.' }
                labels = @{ type = 'array'; items = @{ type = 'string' }; description = 'Optional existing labels to assign when creating the issue.' }
            }
            required = @('owner', 'repo', 'title')
        }
    },
    @{
        name = 'update_issue'
        description = 'Updates an issue title, body, and/or open/closed state.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner        = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo         = @{ type = 'string'; description = 'Repository name.' }
                issue_number = @{ type = 'integer'; minimum = 1; description = 'Issue number.' }
                title        = @{ type = 'string'; description = 'New issue title.' }
                body         = @{ type = 'string'; description = 'New issue description in Markdown; an empty string clears it.' }
                state        = @{ type = 'string'; enum = @('open', 'closed'); description = 'New issue state.' }
                state_reason = @{ type = 'string'; enum = @('completed', 'not_planned', 'reopened'); description = 'Optional reason, supplied together with state.' }
            }
            required = @('owner', 'repo', 'issue_number')
        }
    },
    @{
        name = 'add_issue_labels'
        description = 'Adds one or more existing labels to an issue without removing its current labels.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner        = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo         = @{ type = 'string'; description = 'Repository name.' }
                issue_number = @{ type = 'integer'; minimum = 1; description = 'Issue number.' }
                labels       = @{ type = 'array'; items = @{ type = 'string' }; description = 'One or more existing repository labels to add.' }
            }
            required = @('owner', 'repo', 'issue_number', 'labels')
        }
    },
    @{
        name = 'create_label'
        description = 'Creates a label in a GitHub repository.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner       = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo        = @{ type = 'string'; description = 'Repository name.' }
                name        = @{ type = 'string'; description = 'Label name (1-50 characters).' }
                color       = @{ type = 'string'; description = 'Optional six-character hexadecimal color without #.' }
                description = @{ type = 'string'; description = 'Optional label description.' }
            }
            required = @('owner', 'repo', 'name')
        }
    },
    @{
        name = 'remove_issue_labels'
        description = 'Removes one or more specified labels from an issue.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner        = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo         = @{ type = 'string'; description = 'Repository name.' }
                issue_number = @{ type = 'integer'; minimum = 1; description = 'Issue number.' }
                labels       = @{ type = 'array'; items = @{ type = 'string' }; description = 'One or more issue labels to remove.' }
            }
            required = @('owner', 'repo', 'issue_number', 'labels')
        }
    },
    @{
        name = 'add_issue_comment'
        description = 'Adds a comment to a GitHub issue.'
        inputSchema = @{
            type = 'object'
            properties = @{
                owner        = @{ type = 'string'; description = 'Repository owner (user or organization).' }
                repo         = @{ type = 'string'; description = 'Repository name.' }
                issue_number = @{ type = 'integer'; minimum = 1; description = 'Issue number.' }
                body         = @{ type = 'string'; description = 'Comment text in Markdown (1-65536 characters).' }
            }
            required = @('owner', 'repo', 'issue_number', 'body')
        }
    }
)

while ($null -ne ($line = [Console]::In.ReadLine())) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $msg = $line | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Send @{ jsonrpc = '2.0'; id = $null; error = @{ code = -32700; message = 'Invalid JSON request.' } }
        continue
    }
    if ($null -eq $msg.id) { continue }

    switch ($msg.method) {
        'initialize' {
            Send @{
                jsonrpc = '2.0'; id = $msg.id
                result = @{
                    protocolVersion = $msg.params.protocolVersion
                    capabilities    = @{ tools = @{} }
                    serverInfo      = @{ name = 'github-windows'; version = '1.1.0' }
                }
            }
        }
        'tools/list' {
            Send @{ jsonrpc = '2.0'; id = $msg.id; result = @{ tools = $tools } }
        }
        'tools/call' {
            try {
                $arguments = $msg.params.arguments
                switch ($msg.params.name) {
                    'get_repo' { $result = Get-GitHubRepo $arguments.owner $arguments.repo }
                    'create_issue' { $result = New-GitHubIssue $arguments }
                    'update_issue' { $result = Set-GitHubIssue $arguments }
                    'add_issue_labels' { $result = Add-GitHubIssueLabels $arguments }
                    'create_label' { $result = New-GitHubLabel $arguments }
                    'remove_issue_labels' { $result = Remove-GitHubIssueLabels $arguments }
                    'add_issue_comment' { $result = Add-GitHubIssueComment $arguments }
                    default { throw "Unknown tool: $($msg.params.name)" }
                }
                $text = ConvertTo-Json -InputObject $result -Depth 20 -Compress
                Send @{ jsonrpc = '2.0'; id = $msg.id; result = @{ content = @(@{ type = 'text'; text = $text }) } }
            } catch {
                Send @{
                    jsonrpc = '2.0'; id = $msg.id
                    result = @{ isError = $true; content = @(@{ type = 'text'; text = $_.Exception.Message }) }
                }
            }
        }
        'ping' { Send @{ jsonrpc = '2.0'; id = $msg.id; result = @{} } }
        default {
            Send @{ jsonrpc = '2.0'; id = $msg.id; error = @{ code = -32601; message = "Method not found: $($msg.method)" } }
        }
    }
}
