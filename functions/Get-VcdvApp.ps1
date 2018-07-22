function Get-VcdvApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Session = $GlobalvCDSession
    )
    try {
        Write-Verbose "Query REST API for vApp: $Name"
        $Uri = $APIurl + "/query?type=vApp&filter=(name==$Name)"
        $vAppXml = Invoke-RestMethod -Uri $Uri -Method GET -WebSession $Session -ErrorAction Stop
        if ($vAppXml.QueryResultRecords.total -eq 0) {
            Write-Error "Found $($vAppXml.QueryResultRecords.total) vApps"
        } else {
            Write-Verbose "Found $($vAppXml.QueryResultRecords.total) vApps"
            Return $vAppXml.QueryResultRecords.vAppRecord
        }
    } catch {
        throw "Could not find vApp `"$Name`""
    }
}