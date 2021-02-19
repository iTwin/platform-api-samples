
function Get-Base64Uri {
    param (
        [Parameter(Mandatory)][System.Byte[]]$bytes
    )

    $base64 = [Convert]::ToBase64String($bytes)
    $base64url = $base64 -replace '\+', '-' -replace '/', '_'
    return $base64url.TrimEnd('=')
}

function New-RandomBase64UrlString {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object Byte[] 32
    $rng.GetBytes($bytes)

    return Get-Base64Uri $bytes
}

function New-Sha256Hash {
    param (
        [Parameter(Mandatory)][string]$string
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $hash = $sha256.ComputeHash($bytes)

    return Get-Base64Uri($hash)
}
