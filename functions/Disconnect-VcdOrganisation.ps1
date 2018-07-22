function Disconnect-VcdOrganisation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Session = $GlobalvCDSession
    )
    try {
        $sessionURL = $APIurl + '/session'
        Invoke-RestMethod -Uri $sessionurl -Method DELETE -WebSession $Session -ErrorAction Stop | Out-Null
        Return $true
    } catch {
        Return $false
    }
}