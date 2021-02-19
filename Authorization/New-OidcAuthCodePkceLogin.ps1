[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory, ParameterSetName = "Invoke")]
    [string]$clientId,

    [Parameter(Mandatory = $false, ParameterSetName = "Invoke")]
    [string]$state,

    [Parameter(Mandatory, ParameterSetName = "Invoke")]
    [string]$scope,

    [Parameter(ParameterSetName = "Invoke")]
    [string]$authorizationHostname = "ims.bentley.com",

    [Parameter(Mandatory, ParameterSetName = "Invoke")]
    [string]$redirectUri,

    [Parameter(Mandatory, ParameterSetName = "Callback")]
    [string]$url,

    [Parameter(Mandatory, ParameterSetName = "Callback")]
    [string]$pipeName
)

. $PSScriptRoot\..\Utilities\Utils.ps1;

$ErrorActionPreference = 'Stop'


$authorizeEndpoint = "https://$authorizationHostname/connect/authorize";
$tokenEndpoint = "https://$authorizationHostname/connect/token";


if (-not $pipeName) {
    $redirect = [System.Uri]$redirectUri
    $schemeName = $redirect.Scheme
    $rootKey = "HKCU:\Software\Classes\$schemeName"

    $pwshPath = (Get-Process -Id $PID).Path
    $pipeName = "\\.\pipe\$(New-Guid)"

    # Register the temporary URL handler with the pipe name for this session only
    New-Item -Path $rootKey -Value "URL:$schemeName" -Force | Out-Null;
    New-ItemProperty -Path $rootKey -Name "URL Protocol" | Out-Null;
    New-Item -Path "$rootKey\shell" -Value "open" -Force | Out-Null;
    New-Item -Path "$rootKey\shell\open\command" -Force -Value """$pwshPath"" -NoProfile -File ""$PSCommandPath"" -pipeName ""$pipeName"" -url ""%1""" | Out-Null;

    # Create and invoke authorization url
    $codeVerifier = New-RandomBase64UrlString
    $codeChallenge = New-Sha256Hash $codeVerifier
    if( [string]::IsNullOrEmpty( $state )) {
        $state = New-RandomBase64UrlString
    }
    $scope = [System.Uri]::EscapeDataString($scope)
    $authorizeUrl = $authorizeEndpoint +
        "?response_type=code" +
        "&code_challenge=$codeChallenge" +
        "&code_challenge_method=S256" +
        "&client_id=$clientId" +
        "&redirect_uri=$redirectUri" +
        "&scope=$scope" +
        "&state=$state"

    Write-Verbose "Opening '$authorizeUrl' in system browser";
    Start-Process $authorizeUrl | Out-Null;

    try {
        # Start up the named pipe to receive URL from URL handler invocation
        # [System.IO.Pipes.PipeOptions]::Asynchronous is required for handling timeout
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)

        # Timeout after 5 minutes
        $cts = New-Object System.Threading.CancellationTokenSource([timespan]::FromMinutes(5))
        $pipe.WaitForConnectionAsync($cts.Token).GetAwaiter().GetResult() | Out-Null;

        $sr = New-Object System.IO.StreamReader($pipe) 
        $callback = [uri]$sr.ReadToEnd()
        Write-Verbose "Received callback '$callback'"

        $sr.Dispose()
    }
    catch [System.Threading.Tasks.TaskCanceledException] {
        Write-Warning "Timed out while waiting for response"
    }
    finally {
        $pipe.Dispose()

        # remove the url handler registration
        Remove-Item -Path $rootKey -Recurse
    }

    $query = [System.Web.HttpUtility]::ParseQueryString($callback.Query)
    if ($query["error"]) {
        Write-Error "Received an error: $($query["error"]) $($query["error_description"])"
    }

    $code = $query["code"]
    if (-not $code) {
        Write-Error "Authorization code was not found in callback"
    }

    $callbackState = $query["state"]
    if (-not $callbackState) {
        Write-Error "State was not found in callback"
    }

    if ($callbackState -ne $state) {
        Write-Error "State did not match"
    }

    $payload = "grant_type=authorization_code" +
        "&client_id=$clientId" +
        "&code=$code" +
        "&redirect_uri=$redirectUri" +
        "&code_verifier=$codeVerifier"

    $headers = @{
        "Accept" = "application/json";
    }
    $tokenResponse = $payload | Invoke-WebRequest -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Method Post -Headers $headers | ConvertFrom-Json -AsHashtable
    $accessToken = $tokenResponse["access_token"]
    Write-Verbose "Received access_token: $accessToken"

    return $accessToken;
}
else {
    Write-Verbose $url
    $pipe = New-Object System.IO.Pipes.NamedPipeClientStream($pipeName)
    $pipe.Connect() 

    $sw = New-Object System.IO.StreamWriter($pipe)
    $sw.Write($url)

    $sw.Dispose()
    $pipe.Dispose()
}
