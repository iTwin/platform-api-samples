<#

This sample is a companion to a tutorial found on https://developer.bentley.com/, under the Administration API group.
It will demonstrate how to copy users from one project to another.

#>

param(
    <#
    Source project ID

    You will need to have access to, or create a new, project to use this sample.
    #> 
    [Parameter(Mandatory = $false)][string]$sourceProjectId,

    <#
    Destination project ID

    You will need to have access to, or create a new, project to use this sample.
    #> 
    [Parameter(Mandatory = $false)][string]$destinationProjectId,

    <# 
    Client ID 

    You can view your existing clients, or register a new one, at https://developer.bentley.com/my-apps.
    This sample requires an client registered with the Authorization Code flow and PKCE required.
    #>
    [Parameter(Mandatory)][string]$clientId, 

    <#
    Redirect URI

    This is a Redirect URI that is part if the client registration.
    #>
    [Parameter(Mandatory)][string]$RedirectUri
)

. $PSScriptRoot\..\..\Utilities\Utils.ps1;
. $PSScriptRoot\..\..\Authorization\AuthUtils.ps1;


<# 1. Request access token for use in Authorization header. #>
$scopes = 'projects:read projects:modify';
$state = New-AuthState -String ( $MyInvocation.MyCommand.Name + $env:computername );
$token = New-UserLogin -ClientId $clientId -redirectUri $redirectUri -Scopes $scopes -State $state;
if( [string]::IsNullOrEmpty($token) ) {
    Write-Host "Login failed." -ForegroundColor Red;
    Exit;
}

<# ... and create the required HTTP headers, using the access token retrieved in the previous step. #>
$headers = @{
    Authorization = "Bearer $token";
}

<# 2. Set up urls #>
$baseUrl = "https://api.bentley.com/projects";

<# 3. Show members and roles before import #>
Write-Host "Members and roles BEFORE import - " $MyInvocation.MyCommand -ForegroundColor Cyan;
$script = "$PSScriptRoot\..\Get-ProjectMembers.ps1";
& $script -projectId $destinationProjectId -authToken $token;

<# 4. Get source project roles and team members#>
$sourceRolesResponse = Invoke-RestMethod -Uri "$baseUrl/$sourceProjectId/roles" -Method Get -Headers $headers;
$sourceTeamMembersResponse = Invoke-RestMethod -Uri "$baseUrl/$sourceProjectId/members" -Method Get -Headers $headers;

<# 5. Get existing roles and members of the destination project. #>
$destinationRolesResponse = Invoke-RestMethod -Uri "$baseUrl/$destinationProjectId/roles" -Method Get -Headers $headers;
$destinationTeamMembersResponse = Invoke-RestMethod -Uri "$baseUrl/$destinationProjectId/members" -Method Get -Headers $headers;

<# 6. Create a new role in the destination project for each role in source project#>
foreach ($role in $sourceRolesResponse.roles){
    Write-Verbose ( "found source role " + $role.displayName );
    <# If a role with this name already exists in the destination project skip it #>
    if($destinationRolesResponse.roles.Where({$_.displayName -eq $role.displayName}).Count -gt 0){
        Write-Verbose "...found matching destination role";
        continue;
    }

    $requestUrl = "$baseUrl/$destinationProjectId/roles";
    $requestBody = @{
        displayName = $role.displayName;
        description = $role.description;
    } | ConvertTo-Json;

    Write-Verbose "Roles request Url $requestUrl";
    Write-Verbose "Roles request Body: $requestBody";

    try {
        $createResponse = Invoke-RestMethod -Uri $requestUrl -Method Post -Headers $headers -Body $requestBody;
        $roleId = $createResponse.role.id;
        $roleName = $createResponse.role.displayName;
        Write-Verbose "...added role $roleName ($roleId)";
    } catch {
        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
        } else {
            $_
        }
    }
}

<# 7. Fetch the list of roles with the newly created ones #>
try {
    $destinationRolesResponse = Invoke-RestMethod -Uri "$baseUrl/$destinationProjectId/roles" -Method Get -Headers $headers;
} catch {
    if($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
    } else {
        $_
    }
}

<# 8. Add a new user in the destination project for each user in the source project #>
foreach($teamMember in $sourceTeamMembersResponse.members){
    <# If a user with this id already exists in the destination project skip it #>
    Write-Verbose ( "found source member " + $teamMember.email );
    if($destinationTeamMembersResponse.members.Where({$_.userId -eq $teamMember.userId}).Count -gt 0){
        Write-Verbose "...found matching destination member";
        continue;
    }
    Write-Verbose ("...adding member " + $teamMember.email );

    $teamMemberRoleIds = @()
    foreach($memberRole in $teamMember.roles){
        Write-Verbose "......searching for member role $memberRole in the destination project";
        $teamMemberRoleIds += $destinationRolesResponse.roles.Where({$_.displayName -eq $memberRole}) | select -ExpandProperty id;
    }

    $requestUrl = "$baseUrl/$destinationProjectId/members";
    $requestBody = @{
        userId = $teamMember.userId;
        roleIds = $teamMemberRoleIds;
    } | ConvertTo-Json;

    Write-Verbose "Member request Url $requestUrl";
    Write-Verbose "Member request Body: $requestBody";

    try {
        Invoke-RestMethod -Uri $requestUrl -Method Post -Headers $headers -Body $requestBody;
    } catch {
        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
        } else {
            $_
        }
    }
}

<# 9. Show members and roles after import #>
Write-Host "Members and roles AFTER import - " $MyInvocation.MyCommand -ForegroundColor Cyan;
$script = "$PSScriptRoot\..\Get-ProjectMembers.ps1";
& $script -projectId $destinationProjectId -authToken $token;
