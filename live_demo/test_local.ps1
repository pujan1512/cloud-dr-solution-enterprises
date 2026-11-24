$ErrorActionPreference = 'Stop'
$global:MockCalls = [System.Collections.Generic.List[string]]::new()
function global:aws {
    $global:LASTEXITCODE = 0
    $line = $args -join ' '
    $global:MockCalls.Add($line)
    if ($line -match 'describe-stacks' -and $line -match 'OutputKey') {
        if ($line -match 'PublicIP') { return '203.0.113.10' }
        if ($line -match 'InstanceId') { return 'i-test' }
        if ($line -match 'WebURL') { return 'http://203.0.113.10/' }
        if ($line -match 'NameServers') { return 'ns-1.example.net, ns-2.example.net' }
    }
    if ($line -match 'ssm send-command') {
        $arg = $args | Where-Object { $_ -like 'file://*' } | Select-Object -First 1
        if (!$arg) { throw 'Missing SSM parameter file' }
        $payload = Get-Content -Raw -LiteralPath $arg.Substring(7) | ConvertFrom-Json
        if ($payload.commands[0] -notmatch '^sudo systemctl (start|stop) httpd$') { throw 'Unexpected SSM command' }
        return 'mock-command-id'
    }
    return '{}'
}
try {
    $demo = Join-Path $PSScriptRoot 'demo.ps1'
    & $demo -Action deploy-regions
    & $demo -Action deploy-dns -DomainName dr.example.com
    & $demo -Action stop-primary
    & $demo -Action start-primary
    if (($global:MockCalls | Where-Object { $_ -match '^cloudformation deploy' }).Count -ne 3) { throw 'Expected three deployments' }
    if (($global:MockCalls | Where-Object { $_ -match '^ssm send-command' }).Count -ne 2) { throw 'Expected two SSM commands' }
    Write-Host 'PASS: mocked AWS CLI deploy and stop/start command flow'
} finally { Remove-Item Function:\global:aws -ErrorAction SilentlyContinue }
