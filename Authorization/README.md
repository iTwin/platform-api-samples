# Authorization

Authorization is required for all iTwin Platform API endpoints.  

API samples that show how to use these endpoints also require authorization.

## Powershell code to obtain an authorization token

Each sample already includes code that obtains an authoriztaion token.  Explanations of authorization steps are included here rather than in the samples in order to allow the focus in the samples to be on what the sample demonstrates.

These samples require an Authorization Code + PKCE client.  Registration of a **Desktop/Mobile** app will give you an Authorization Code + PKCE client.

1. Include required files

    - These required files separate out re-usable functionality

    ```Powershell
    . $PSScriptRoot\..\Authorization\AuthUtils.ps1;
    ```

2. Define required variables

    - Each developer must provide their own values for these

    ```Powershell
    [string]$clientId       # This is the client ID from your app registration
    [string]$redirectUri    # This is the Redirect URI from your app registration
    ```

3. Obtain a unique *state* value.  This is required by the Authorization Code + PKCE flow.

    ```Powershell
    $state = New-AuthState -String ( $MyInvocation.MyCommand.Name + $env:computername );
    ```

4. Call the New-OidcAuthCodePkceLogin script to allow the user to login and obtain an access (aka authorization) token

    - This script will open a browser and make a request to the host specified by *authorizationHostName*.
    - Once the user has successfully logged in, the access token will be returned.

    ```Powershell
    $script = "$PSScriptRoot\..\Authorization\New-OidcAuthCodePkceLogin.ps1";
    $access_token = & $script -clientId $clientId -scope 'itwin-platform' -redirectUri $redirectUri -state $state -authorizationHostname 'ims.bentley.com'
    ```
