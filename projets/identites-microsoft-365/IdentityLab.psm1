Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Copy-LabState {
    param([Parameter(Mandatory)]$State)
    return ($State | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable)
}

function Get-LabIssues {
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][string]$UserId)
    if (-not $State.users.Contains($UserId)) { throw "Unknown synthetic user: $UserId" }
    $user = $State.users[$UserId]
    $issues = [System.Collections.Generic.List[string]]::new()
    if (-not $user.enabled) { $issues.Add('ACCOUNT_DISABLED') }
    if ($user.enabled -and -not $user.mfaRegistered) { $issues.Add('MFA_NOT_REGISTERED') }
    foreach ($service in @('Exchange Online','Teams','SharePoint Online','OneDrive')) {
        $grants = @($user.groups | Where-Object { $State.groups[$_].services -contains $service })
        if ($user.enabled -and $grants.Count -eq 0) { $issues.Add("NO_ENTITLEMENT: $service") }
    }
    if (-not $user.enabled -and ($user.groups.Count -gt 0 -or $user.sessionsActive)) {
        $issues.Add('LEAVER_ACCESS_REMAINS')
    }
    return $issues.ToArray()
}

function Invoke-LabChange {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)]$Request)
    # All changes occur in a copied synthetic document. No SDK, cloud token or network call is used.
    $result = Copy-LabState $State
    if ($Request.type -notin @('joiner','mover','leaver')) { throw 'Unsupported lifecycle request' }
    if ($Request.approval -ne 'approved') { throw 'Change requires an approved synthetic ticket' }
    if ([string]::IsNullOrWhiteSpace($Request.ticketId)) { throw 'Ticket ID is required' }
    if ([string]::IsNullOrWhiteSpace($Request.userId)) { throw 'Synthetic user ID is required' }
    if ($result.processedTickets -contains $Request.ticketId) {
        return @{ state=$result; changed=$false; status='ALREADY_APPLIED'; ticketId=$Request.ticketId }
    }
    $exists = $result.users.Contains($Request.userId)
    if ($Request.type -eq 'joiner') {
        if ($exists) { throw 'Joiner already exists; review the ticket before making changes' }
        if ([string]::IsNullOrWhiteSpace($Request.displayName)) { throw 'Display name is required' }
        $result.users[$Request.userId] = @{
            displayName=$Request.displayName; department=$Request.department
            enabled=$true; mfaRegistered=$false; sessionsActive=$false; groups=@()
        }
    } elseif (-not $exists) { throw 'Mover/leaver user does not exist' }
    $user = $result.users[$Request.userId]
    if ($Request.type -in @('joiner','mover')) {
        foreach ($groupId in $Request.groups) {
            if (-not $result.groups.Contains($groupId)) { throw "Unknown group: $groupId" }
        }
        $user.groups = @($Request.groups | Sort-Object -Unique)
        $user.department = $Request.department
    } else {
        $user.enabled = $false
        $user.sessionsActive = $false
        $user.groups = @()
    }
    $result.processedTickets = @($result.processedTickets) + $Request.ticketId
    $result.audit = @($result.audit) + @{
        ticketId=$Request.ticketId; userId=$Request.userId; action=$Request.type
        approval=$Request.approval; executor='OFFLINE_LAB'; timestampUtc=[DateTime]::UtcNow.ToString('o')
    }
    return @{ state=$result; changed=$true; status='APPLIED_OFFLINE'; ticketId=$Request.ticketId }
}

function Get-LabRequestPlan {
    param([Parameter(Mandatory)]$Request, $State = $null)
    # Illustrative Graph-style request shapes. IDs are fixture IDs; the output is never sent.
    $id = [Uri]::EscapeDataString($Request.userId)
    $plan = [System.Collections.Generic.List[object]]::new()
    if ($Request.type -eq 'joiner') {
        $plan.Add(@{method='POST'; path='/users'; note='Illustration only: real creation requires additional fields and permissions'})
    } elseif ($Request.type -eq 'mover') {
        $plan.Add(@{method='PATCH'; path="/users/$id"; note='Review old and new memberships before a live change'})
    } elseif ($Request.type -eq 'leaver') {
        $plan.Add(@{method='PATCH'; path="/users/$id"; body=@{accountEnabled=$false}})
        $plan.Add(@{method='POST'; path="/users/$id/revokeSignInSessions"; note='Session revocation is eventually effective in a real tenant'})
    } else { throw 'Unsupported lifecycle request' }
    $oldGroups = @()
    if ($null -ne $State -and $State.users.Contains($Request.userId)) {
        $oldGroups = @($State.users[$Request.userId].groups)
    }
    $desiredGroups = @()
    if ($Request.type -in @('joiner','mover')) { $desiredGroups = @($Request.groups) }
    foreach ($groupId in $oldGroups) {
        if ($desiredGroups -notcontains $groupId) {
            $group = [Uri]::EscapeDataString($groupId)
            $plan.Add(@{method='DELETE'; path="/groups/$group/members/$id/`$ref"; note='The $ref suffix removes membership, not the directory object'})
        }
    }
    foreach ($groupId in $desiredGroups) {
        if ($oldGroups -notcontains $groupId) {
            $group = [Uri]::EscapeDataString($groupId)
            $plan.Add(@{method='POST'; path="/groups/$group/members/`$ref"; body=@{'@odata.id'="https://graph.microsoft.com/v1.0/directoryObjects/$id"}})
        }
    }
    return @{ mode='OFFLINE_PLAN_ONLY'; cloudCallsMade=0; ticketId=$Request.ticketId; requests=$plan.ToArray() }
}

Export-ModuleMember -Function Copy-LabState, Get-LabIssues, Invoke-LabChange, Get-LabRequestPlan
