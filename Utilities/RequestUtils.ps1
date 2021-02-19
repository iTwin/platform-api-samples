

function Get-ResponseFromRestMethod {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory=$false)][string]$Body = [string]::Empty,
        [Parameter(Mandatory=$false)][string]$ContentType = 'application/x-www-form-urlencoded',
        [Parameter(Mandatory=$false)][Hashtable]$Headers = @{}
    )

    try {
        Write-Verbose "Request URL: $Url";
        Write-Verbose "Request body: $Body";
        $response = Invoke-RestMethod -Method $Method -Uri $Uri -Body $Body -ContentType $ContentType -Headers $Headers; 
        $StatusCode = $response.StatusCode;
    } catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__

        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
        } else {
            $_
        }

        $response = $_.Exception.Response;
    }
    Write-Verbose ( "Response status: " + $StatusCode );
    if( 401 -EQ $response.StatusCode) {
        $response.Headers | ForEach-Object {
            if( $_.Key -EQ 'WWW-Authenticate' ) {
                Write-Host "WWW-Authenticate: " $_.Value -ForegroundColor Red;
            }
        }
    }
}

function Get-ResponseFromWebRequest {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory=$false)][string]$Body = [string]::Empty,
        [Parameter(Mandatory=$false)][string]$ContentType = 'application/x-www-form-urlencoded',
        [Parameter(Mandatory=$false)][Hashtable]$Headers = @{}
    )

    try {
        Write-Verbose "Request URL: $Url";
        Write-Verbose "Request body: $Body";
        $response = Invoke-WebRequest -Method $Method -Uri $Uri -Body $Body -ContentType $ContentType -Headers $Headers; 
        $StatusCode = $response.StatusCode;
    } catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__

        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red;
        } else {
            $_
        }

        $response = $_.Exception.Response;
    }
    Write-Verbose ( "Response status: " + $StatusCode );
    if( 401 -EQ $response.StatusCode) {
        $response.Headers | ForEach-Object {
            if( $_.Key -EQ 'WWW-Authenticate' ) {
                Write-Host "WWW-Authenticate: " $_.Value -ForegroundColor Red;
            }
        }
    }
    
    return $response;
}

Write-Verbose "...RequestUtils.ps1 loaded...";
