param(
    [ValidateSet('deploy-regions','deploy-dns','status','stop-primary','start-primary')]
    [Parameter(Mandatory=$true)][string]$Action,
    [string]$PrimaryRegion = 'us-east-1',
    [string]$RecoveryRegion = 'us-west-2',
    [string]$DomainName = '',
    [string]$InstanceType = 't3.micro'
)
$ErrorActionPreference = 'Stop'
$primaryStack = 'clg-dr-primary'
$recoveryStack = 'clg-dr-recovery'
$dnsStack = 'clg-dr-dns'
$regionalTemplate = Join-Path $PSScriptRoot 'regional.yaml'
$dnsTemplate = Join-Path $PSScriptRoot 'dns.yaml'
function Invoke-Aws {
    param([string[]]$Arguments)
    & aws @Arguments --no-cli-pager
    if ($LASTEXITCODE -ne 0) { throw "AWS command failed (exit $LASTEXITCODE)." }
}
function Get-Output {
    param([string]$Stack, [string]$Region, [string]$Key)
    $value = & aws cloudformation describe-stacks --stack-name $Stack --region $Region --query "Stacks[0].Outputs[?OutputKey=='$Key'].OutputValue | [0]" --output text --no-cli-pager
    if ($LASTEXITCODE -ne 0 -or !$value -or $value -eq 'None') { throw "Missing output $Key from $Stack in $Region." }
    return $value.Trim()
}
function Deploy-Regional {
    param([string]$Stack, [string]$Region, [string]$Role)
    Invoke-Aws @('cloudformation','deploy','--stack-name',$Stack,'--region',$Region,'--template-file',$regionalTemplate,'--capabilities','CAPABILITY_IAM','--parameter-overrides',"SiteRole=$Role","InstanceType=$InstanceType",'--no-fail-on-empty-changeset')
}
switch ($Action) {
    'deploy-regions' {
        if ($PrimaryRegion -eq $RecoveryRegion) { throw 'Choose two different AWS regions.' }
        Invoke-Aws @('sts','get-caller-identity')
        Deploy-Regional $primaryStack $PrimaryRegion 'Primary'
        Deploy-Regional $recoveryStack $RecoveryRegion 'Recovery'
        Write-Host 'Stacks created. Web server startup can take several more minutes.'
        Write-Host "Primary URL:  $(Get-Output $primaryStack $PrimaryRegion 'WebURL')"
        Write-Host "Recovery URL: $(Get-Output $recoveryStack $RecoveryRegion 'WebURL')"
    }
    'deploy-dns' {
        if (!$DomainName) { throw 'Provide -DomainName using a domain or subdomain you control.' }
        $primaryIP = Get-Output $primaryStack $PrimaryRegion 'PublicIP'
        $recoveryIP = Get-Output $recoveryStack $RecoveryRegion 'PublicIP'
        Invoke-Aws @('cloudformation','deploy','--stack-name',$dnsStack,'--region',$PrimaryRegion,'--template-file',$dnsTemplate,'--parameter-overrides',"DomainName=$DomainName","PrimaryIP=$primaryIP","RecoveryIP=$recoveryIP",'--no-fail-on-empty-changeset')
        Write-Host "Authoritative name servers: $(Get-Output $dnsStack $PrimaryRegion 'NameServers')"
        Write-Host 'Delegate the domain or subdomain at its registrar/parent DNS provider before normal public lookup will work.'
    }
    'status' {
        foreach ($item in @(@($primaryStack,$PrimaryRegion),@($recoveryStack,$RecoveryRegion),@($dnsStack,$PrimaryRegion))) {
            Write-Host "`n$($item[0]) in $($item[1]):"
            & aws cloudformation describe-stacks --stack-name $item[0] --region $item[1] --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}' --output json --no-cli-pager
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Stack unavailable or AWS call failed.' }
        }
    }
    { $_ -in 'stop-primary','start-primary' } {
        $instance = Get-Output $primaryStack $PrimaryRegion 'InstanceId'
        $command = if ($Action -eq 'stop-primary') { 'sudo systemctl stop httpd' } else { 'sudo systemctl start httpd' }
        $parameters = @{ commands = @($command) } | ConvertTo-Json -Compress
        $path = Join-Path ([System.IO.Path]::GetTempPath()) ("clg-dr-ssm-" + [guid]::NewGuid().ToString('N') + '.json')
        try {
            [System.IO.File]::WriteAllText($path, $parameters, [System.Text.UTF8Encoding]::new($false))
            Invoke-Aws @('ssm','send-command','--region',$PrimaryRegion,'--instance-ids',$instance,'--document-name','AWS-RunShellScript','--parameters',"file://$path",'--comment',"CLG DR demonstration: $Action",'--query','Command.CommandId','--output','text')
            Write-Host 'Command submitted; confirm its result in Systems Manager Run Command. DNS health changes are not instantaneous.'
        } finally { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    }
}
