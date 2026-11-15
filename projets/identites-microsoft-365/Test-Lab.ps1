Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'IdentityLab.psm1') -Force
$fixture = Get-Content (Join-Path $PSScriptRoot 'fixtures/tenant.json') -Raw | ConvertFrom-Json -AsHashtable
$requests = Get-Content (Join-Path $PSScriptRoot 'fixtures/requests.json') -Raw | ConvertFrom-Json -AsHashtable
$results = [System.Collections.Generic.List[object]]::new()
function Check([string]$Name, [scriptblock]$Test) {
    try { & $Test; $results.Add(@{name=$Name;status='PASS'}) }
    catch { $results.Add(@{name=$Name;status='FAIL';error=$_.Exception.Message}) }
}
function Assert-True($Condition) { if (-not $Condition) { throw 'Assertion failed' } }
function Assert-Throws([scriptblock]$Action) {
    $threw = $false
    try { & $Action | Out-Null } catch { $threw = $true }
    Assert-True $threw
}
Check 'Healthy user has zero issues' { Assert-True (@(Get-LabIssues $fixture 'demo-alice').Count -eq 0) }
Check 'MFA missing is detected' { Assert-True (@(Get-LabIssues $fixture 'demo-bob') -contains 'MFA_NOT_REGISTERED') }
Check 'Missing mailbox entitlement is detected' { Assert-True (@(Get-LabIssues $fixture 'demo-bob') -contains 'NO_ENTITLEMENT: Exchange Online') }
Check 'Residual leaver access is detected' { Assert-True (@(Get-LabIssues $fixture 'demo-carol') -contains 'LEAVER_ACCESS_REMAINS') }
Check 'Unknown user diagnosis fails' { Assert-Throws { Get-LabIssues $fixture 'unknown' } }
Check 'Joiner creates user and desired memberships' {
    $r = Invoke-LabChange $fixture $requests[0]
    Assert-True ($r.state.users['demo-dan'].enabled -and $r.state.users['demo-dan'].groups.Count -eq 2)
}
Check 'New account still requires real MFA enrolment' {
    $r = Invoke-LabChange $fixture $requests[0]
    Assert-True (@(Get-LabIssues $r.state 'demo-dan') -contains 'MFA_NOT_REGISTERED')
}
Check 'Change leaves original input untouched' {
    Invoke-LabChange $fixture $requests[0] | Out-Null
    Assert-True (-not $fixture.users.Contains('demo-dan'))
}
Check 'Mover removes old group and grants desired groups' {
    $r = Invoke-LabChange $fixture $requests[1]
    Assert-True ($r.state.users['demo-bob'].groups -notcontains 'grp-hr-private')
    Assert-True ($r.state.users['demo-bob'].groups -contains 'grp-collaboration')
}
Check 'Leaver disables account removes groups and revokes simulated sessions' {
    $r = Invoke-LabChange $fixture $requests[2]
    $u = $r.state.users['demo-carol']
    Assert-True (-not $u.enabled -and -not $u.sessionsActive -and $u.groups.Count -eq 0)
}
Check 'Retry is idempotent and adds no duplicate audit entry' {
    $a = Invoke-LabChange $fixture $requests[0]
    $b = Invoke-LabChange $a.state $requests[0]
    Assert-True (-not $b.changed -and $b.state.audit.Count -eq 1)
}
Check 'Unapproved request rejected without mutation' {
    $q = Copy-LabState $requests[0]; $q.approval='pending'
    Assert-Throws { Invoke-LabChange $fixture $q }
    Assert-True ($fixture.processedTickets.Count -eq 0)
}
Check 'Unknown group rejected before committing changes' {
    $q = Copy-LabState $requests[1]; $q.groups=@('missing')
    Assert-Throws { Invoke-LabChange $fixture $q }
    Assert-True ($fixture.users['demo-bob'].groups -contains 'grp-hr-private')
}
Check 'Unknown lifecycle request rejected' {
    $q = Copy-LabState $requests[0]; $q.type='grant-admin'
    Assert-Throws { Invoke-LabChange $fixture $q }
}
Check 'Duplicate joiner on a new ticket rejected' {
    $a = Invoke-LabChange $fixture $requests[0]
    $q = Copy-LabState $requests[0]; $q.ticketId='NEW-ID'
    Assert-Throws { Invoke-LabChange $a.state $q }
}
Check 'Request planner explicitly reports offline mode and zero cloud calls' {
    $p = Get-LabRequestPlan $requests[2]
    Assert-True ($p.mode -eq 'OFFLINE_PLAN_ONLY' -and $p.cloudCallsMade -eq 0 -and $p.requests.Count -eq 2)
}
Check 'Mover membership removal uses safe $ref suffix' {
    $p = Get-LabRequestPlan $requests[1] $fixture
    $remove = @($p.requests | Where-Object { $_.method -eq 'DELETE' })
    Assert-True ($remove.Count -eq 1 -and $remove[0].path -eq '/groups/grp-hr-private/members/demo-bob/$ref')
}
Check 'Membership addition uses @odata.id object reference' {
    $p = Get-LabRequestPlan $requests[0] $fixture
    $add = @($p.requests | Where-Object { $_.path -like '/groups/*' -and $_.method -eq 'POST' })
    Assert-True ($add.Count -eq 2 -and $add[0].body['@odata.id'] -eq 'https://graph.microsoft.com/v1.0/directoryObjects/demo-dan')
}
Check 'Leaver plan removes residual membership via reference' {
    $p = Get-LabRequestPlan $requests[2] $fixture
    Assert-True (@($p.requests | Where-Object { $_.method -eq 'DELETE' }).Count -eq 1)
}
$output = Join-Path $PSScriptRoot 'evidence'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$results.ToArray() | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $output 'test-results.json') -Encoding utf8
$failed = @($results | Where-Object { $_.status -eq 'FAIL' })
Write-Output ("Tests: {0}; passed: {1}; failed: {2}" -f $results.Count,($results.Count-$failed.Count),$failed.Count)
if ($failed.Count) { $failed | ConvertTo-Json; exit 1 }
