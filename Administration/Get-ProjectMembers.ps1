<#
Copyright (c) Bentley Systems, Incorporated. All rights reserved.
See LICENSE.md in the project root for license terms and full copyright notice.
#>

<#

Shared script for getting Project team members.  Used by other scripts to show pre- and post- states.

#>
param(
    <#
    Project ID

    You will need to have access to, or create a new, project to use this sample.
    #> 
    [Parameter(Mandatory = $false)][string]$projectId = [string]::Empty,

    <# 
    Auth token

    This shared script requires the auth token obtained by the calling script.
    #>
    [Parameter(Mandatory)][string]$authToken
)

. $PSScriptRoot\..\Utilities\Utils.ps1;
. $PSScriptRoot\..\Authorization\AuthUtils.ps1;


<# 1. Add token for use in Authorization header. #>
Write-Verbose "Adding auth token $authToken to Authorization header";
$headers = @{
    Authorization = "Bearer $authToken";
}

<# 2. Get list of Project team members #>

Write-Verbose "Getting Project $projectId members and roles..."
$url = "https://api.bentley.com/projects/$projectId/members" 
$response = Invoke-RestMethod -Method GET -Uri $url -ContentType 'application/json' -Headers $headers;

$response.members | ForEach-Object {
    $member = $_;
    Write-Host $member.email;
    $member.roles | ForEach-Object {
        $role = $_;
        Write-Host "`t$role";
    }
}
