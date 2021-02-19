
. $PSScriptRoot\..\Utilities\Utils.ps1

function New-AuthState {
    param(
        [Parameter(Mandatory=$false)][string]$string = [string]::Empty
    )

    if( [string]::IsNullOrEmpty( $string )) {
        $string = New-RandomBase64UrlString;
    }

    # $enc = [system.Text.Encoding]::UTF8;
    # $bytes =  $enc.GetBytes($string);
    
    return New-Sha256Hash -String $string;
}

function New-UserLogin {
    param(
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$redirectUri,
        [Parameter(Mandatory)][string]$Scopes,
        [Parameter(Mandatory)]$State
    )

    # use Authorization Code + PKCE flow
    if( [string]::IsNullOrEmpty($state) ) {
        $state = New-AuthState -String ( $MyInvocation.MyCommand.Name + $env:computername );
    }
    $script = "$PSScriptRoot\New-OidcAuthCodePkceLogin.ps1";
    Write-Host "Login required.  Opening browser to faciliate user login." -ForegroundColor Green;
    Write-Host "You will need to allow the browser to access pwsh in order to login successfully." -ForegroundColor Green;
    Write-Host "Once you have logged in, this script will continue." -ForegroundColor Green;
    $token = & $script -clientId $ClientId -scope $Scopes -redirectUri 'itwin-sample:oauth-redirect' -state $state -authorizationHostname 'ims.bentley.com';
    return $token;
}