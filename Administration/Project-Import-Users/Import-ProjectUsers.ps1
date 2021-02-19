<#

This sample is a companion to a tutorial found on https://developer.bentley.com/, under the Administration API group.  
It will demonstrate how to add users to a Project from a CSV file.

#>
param(
    <#
    Project ID

    You will need to have access to, or create a new, project to use this sample.
    #> 
    [Parameter(Mandatory = $false)][string]$projectId = [string]::Empty,
    <# 
    The absolute or relative path to a CSV file containing a list of users and roles.

    The format of the CSV must be:

        Email, Role(s)
        registertest001@mailinator.com: Team Member
        bctest.usermd@gmail.com: Team Member, Contributor
    #>
    [Parameter(Mandatory = $false)][string]$CsvFileLocation = "$PSScriptRoot/users.csv",

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
$token = New-UserLogin -ClientId $clientId -RedirectUri $RedirectUri -Scopes $scopes -State $state;
if( [string]::IsNullOrEmpty($token) ) {
    Write-Host "Login failed." -ForegroundColor Red;
    Exit;
}

<# ... and create the required HTTP headers, using the access token retrieved in the previous step. #>
$headers = @{
    Authorization = "Bearer $token";
}

<# 2. Show members and roles before import #>
Write-Host "Members and roles BEFORE import - " $MyInvocation.MyCommand -ForegroundColor Cyan;
$script = "$PSScriptRoot\..\Get-ProjectMembers.ps1";
& $script -projectId $projectId -authToken $token;

<# 3. Read users in from CSV. #>
$contents = Import-Csv -Path $CsvFileLocation -Delimiter :;

<# 4. Add each user to the Project #>

$url = "https://api.bentley.com/projects/$projectId/members" 
$contents | ForEach-Object {
    $row = $_;
    
    <# Convert the roles list into an array. #>
    $roles = @();
    ( $row.Roles -split ',' ) | ForEach-Object {
        $roles += , $_;
    }

    <# Create a request object with the username and the role names array. #>
    $requestObject = @{
        email = $row.Email;
        roleNames = $roles;
    }

    <# Convert the request object to JSON. #>
    $body = $requestObject | ConvertTo-Json -Depth 10;

    <# Submit the 'add member' request. #>
    Write-Verbose "Request Url $url";
    Write-Verbose "Request Body: $body";
    try {
        Invoke-RestMethod -Method POST -Uri $url -Body $body -ContentType 'application/json' -Headers $headers;
    } catch {
        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
        } else {
            $_
        }
    }
}

<# 5. Show members and roles after import #>
Write-Host "Members and roles AFTER import - " $MyInvocation.MyCommand -ForegroundColor Cyan;
$script = "$PSScriptRoot\..\Get-ProjectMembers.ps1";
& $script -projectId $projectId -authToken $token;
