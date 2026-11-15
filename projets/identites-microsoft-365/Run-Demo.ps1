param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'evidence/demo'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'IdentityLab.psm1') -Force
$state = Get-Content (Join-Path $PSScriptRoot 'fixtures/tenant.json') -Raw | ConvertFrom-Json -AsHashtable
$requests = Get-Content (Join-Path $PSScriptRoot 'fixtures/requests.json') -Raw | ConvertFrom-Json -AsHashtable
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$findings = foreach ($userId in ($state.users.Keys | Sort-Object)) {
    foreach ($issue in @(Get-LabIssues $state $userId)) {
        [pscustomobject]@{userId=$userId; issue=$issue; mode='SYNTHETIC'; ticket='INC-DEMO-001'}
    }
}
$findings | Export-Csv (Join-Path $OutputDirectory 'findings-before.csv') -NoTypeInformation -Encoding utf8
$plans = foreach ($request in $requests) {
    Get-LabRequestPlan $request $state
    $state = (Invoke-LabChange $state $request).state
}
$state | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $OutputDirectory 'tenant-after.json') -Encoding utf8
$plans | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $OutputDirectory 'request-plan.json') -Encoding utf8
$state.audit | ForEach-Object {
    $entry = @{} + $_
    $entry.timestampUtc = ([DateTime]$entry.timestampUtc).ToUniversalTime().ToString('o')
    [pscustomobject]$entry
} | Export-Csv (Join-Path $OutputDirectory 'audit.csv') -NoTypeInformation -Encoding utf8
$summary = @{mode='OFFLINE_SIMULATION'; changesApplied=$state.audit.Count; users=$state.users.Count; initialFindings=@($findings).Count; cloudCallsMade=0}
$summary | ConvertTo-Json | Set-Content (Join-Path $OutputDirectory 'summary.json') -Encoding utf8
$summary | ConvertTo-Json
