function Disconnect-VcdOrganisation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Headers = $GlobalvCDHeaders
    )
    try {
        $sessionURL = $APIurl + '/session'
        Invoke-RestMethod -Uri $sessionurl -Method DELETE -Headers $Headers -ErrorAction Stop | Out-Null
        Return $true
    } catch {
        Return $false
    }
}