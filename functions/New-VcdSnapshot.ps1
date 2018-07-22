function New-VcdSnapshot {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string]$VM,
        [Parameter(Mandatory = $true)][string]$vAppName,
        [switch]$Memory,
        [switch]$Quiesce,
        [switch]$RunAsync,
        [Parameter(Mandatory = $false)][string]$Description,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Session = $GlobalvCDSession
    )
    Begin {
        if ($Memory.IsPresent) {
            $strMemory = "true"
        } else {
            $strMemory = "false"
        }
        Write-Verbose "Snapshot virtual machine's memory state: $strMemory"
        if ($Quiesce.IsPresent) {
            $strQuiesce = "true"
        } else {
            $strQuiesce = "false"
        }
        Write-Verbose "Quiesce the file system of the virtual machine: $strQuiesce"
    }
    Process {
        try {
            $VMXml = Get-VcdVM -Name $VM -vAppName $vAppName -Session $Session -APIurl $APIurl -ErrorAction Stop
            if ( ($VMXml | Measure-Object | Select-Object -ExpandProperty Count) -ne 1 ) {
                Write-Error "Found $($VMXml | Measure-Object | Select-Object -ExpandProperty Count) VMs. Abort." -ErrorAction Stop
            }

            $Uri = $VMXml.href + "/action/createSnapshot"
            if ([string]::IsNullOrEmpty($Description)) {
                # Description has to be a string
                $Description = "No description"
            }
            $xmlBody = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
            <CreateSnapshotParams xmlns=`"http://www.vmware.com/vcloud/v1.5`" name=`"$(Get-Date -f "yyyyMMdd-HHmm")`" memory=`"$strMemory`" quiesce=`"$strQuiesce`">
            <Description>$Description</Description>
            </CreateSnapshotParams>"

            if ($pscmdlet.ShouldProcess($VM, "Create Snapshot")) {
                $Task = Invoke-RestMethod -Uri $Uri -ContentType "application/vnd.vmware.vcloud.createSnapshotParams+xml" -Method POST -WebSession $Session -Body $xmlBody -ErrorAction Stop
                $Task.Task.id = $Task.Task.id -replace 'urn:vcloud:task:',''
                Write-Verbose $Task.Task.Operation
                if ($RunAsync.IsPresent) {
                    Return $Task.Task
                } else {
                    Wait-VcdTask -TaskId $Task.Task.id
                }
            }
        } catch {
            throw "Could not create Snapshot - $($($_.Exception).Message)"
        }
    }
}