<#
Copyright (c) Bentley Systems, Incorporated. All rights reserved.
See LICENSE.md in the project root for license terms and full copyright notice.
#>

[CmdletBinding()]
PARAM(
    [Parameter(Mandatory)][string]$clientId,
    [Parameter(Mandatory)][string]$clientSecret,
    [Parameter(Mandatory)][string]$scopes,
    [Parameter(Mandatory = $false)][string]$asurl = 'https://ims.bentley.com' # allow override for our internal testing purposes
)


. $PSScriptRoot\RequestUtils.ps1;

try
{
    $Token = $null
    $EndPointURL = "$asurl/connect/token"
    Write-Verbose -Message ('Connecting to "{0}"...' -f $EndPointURL)

    Write-Verbose -Message ('Using scopes "{0}" to request access token...' -f $scopes)
    $encodedSecret = [System.Web.HTTPUtility]::UrlEncode( $clientSecret )
    $body = "grant_type=client_credentials&client_id=$clientId&client_secret=$encodedSecret&scope=$scopes"
    write-verbose "body is '$body'";

    Write-Verbose -Message ('Requesting access token for "{0}"...' -f $clientId)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Token = Get-ResponseFromRestMethod -Method Post -Uri $EndPointURL -Body $body -ContentType 'application/x-www-form-urlencoded' -Headers @{"Accept"="application/json"}

    Write-Verbose -Message ('Created access token successfully : {0}' -f ($Token | Out-String))
    return $Token;
}
catch
{
    Write-Verbose -Message $_.Exception.Message
}
