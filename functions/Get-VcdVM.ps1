function Get-VcdVM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)][string]$vAppName,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Headers = $GlobalvCDHeaders
    )
    try {
        # Check if user has specified a vApp Name
        if ([string]::IsNullOrEmpty($vAppName)) {
            Write-Verbose "Query without vApp"
            $resource = "/query?type=vm&filter=(name==$Name)"
        } else {
            Write-Verbose "Query with vApp $vAppName"
            $vAppXml = Get-VcdvApp -Name $vAppName -Headers $Headers -APIurl $APIurl -ErrorAction Stop
            if ( ($vAppXml | Measure-Object | Select-Object -ExpandProperty Count) -ne 1 ) {
                Write-Error "Found $($vAppXml | Measure-Object | Select-Object -ExpandProperty Count) vApp. Abort." -ErrorAction Stop
            }
            $resource = "/query?type=vm&filter=(name==$Name;container==$($vAppXml.href))"
        }

        # Lookup VM
        Write-Verbose "Query REST API for VM: $Name"
        $Uri = $APIurl + $resource
        $ReturnXml = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers -ErrorAction Stop

        if ($ReturnXml.QueryResultRecords.total -eq 1) {
            Write-Verbose "Found VM $Name"
            Return $ReturnXml.QueryResultRecords.VMRecord
        } elseif ($ReturnXml.QueryResultRecords.total -gt 1) {
            Write-Error "Found more than one ($($ReturnXml.QueryResultRecords.total)) VM. Please be more specific"
        } else {
            Write-Error "Found $($ReturnXml.QueryResultRecords.total) VM"
        }
    } catch {
        throw "Could not find VM `"$Name`""
    }
}