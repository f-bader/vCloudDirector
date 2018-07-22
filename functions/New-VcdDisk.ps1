function New-VcdDisk {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][int64]$CapacityByte,
        [Parameter(Mandatory = $true)][string]$VM,
        [Parameter(Mandatory = $true)][string]$vAppName,
        [switch]$RunAsync,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Session = $GlobalvCDSession
    )
    Process {
        try {
            $VMXml = Get-VcdVM -Name $VM -vAppName $vAppName -Session $Session -APIurl $APIurl -ErrorAction Stop
            if ( ($VMXml | Measure-Object | Select-Object -ExpandProperty Count) -ne 1 ) {
                Write-Error "Found $($VMXml | Measure-Object | Select-Object -ExpandProperty Count) VMs. Abort." -ErrorAction Stop
            }

            $Uri = $VMXml.href + "/virtualHardwareSection/disks"
            $Disks = Invoke-RestMethod -Uri $Uri -Method GET -WebSession $Session

            # Get last hard drive from current VM
            $tmpDisk = $Disks.RasdItemsList.Item | Where-Object {$_.Description -eq "Hard Disk"} | Sort-Object {[int]$_.AddressOnParent} | select-Object -Last 1
            # Clone settings for modification
            $newDisk = $tmpDisk.Clone()
            # Modify clones values
            # ID 7 is reserved for the controller
            # https://communities.vmware.com/thread/345257
            $newDisk.AddressOnParent = [String]([int]$newDisk.AddressOnParent + 1)
            if ($newDisk.AddressOnParent -eq 7) {
                $newDisk.AddressOnParent = [String]([int]$newDisk.AddressOnParent + 1)
            }
            $newDisk.ElementName = "Hard disk $([String]([int]$newDisk.AddressOnParent + 1))"
            $newDisk.InstanceID = [String]([int]$newDisk.InstanceID + 1)
            if ($newDisk.InstanceID -replace '\d+(\d)$', '$1' -eq 7) {
                $newDisk.InstanceID = [String]([int]$newDisk.InstanceID + 1)
            }
            # Ensure that InstanceId is unique
            while ($newDisk.InstanceID -in $Disks.RasdItemsList.Item.InstanceID) {
                $newDisk.InstanceID = [String]([int]$newDisk.InstanceID + 1)
            }
            # Change capacity
            # VirtualQuantity has to be in Bytes
            $newDisk.VirtualQuantity = [String]($CapacityByte)
            # Capacity has to be in MBytes
            $newDisk.HostResource.capacity = [string]($CapacityByte / 1024 / 1024)
            # Add new Disk to XML
            $Disks.RasdItemsList.AppendChild($newDisk) | Out-Null

            if ($pscmdlet.ShouldProcess($VM, "Create Disk")) {
                $Task = Invoke-RestMethod -Uri $Uri -ContentType "application/vnd.vmware.vcloud.rasdItemsList+xml" -Method PUT -WebSession $Session -Body $Disks -ErrorAction Stop
                $Task.Task.id = $Task.Task.id -replace 'urn:vcloud:task:',''
                Write-Verbose $Task.Task.Operation
                if ($RunAsync.IsPresent) {
                    Return $Task.Task
                } else {
                    Wait-VcdTask -TaskId $Task.Task.id
                }
            }
        } catch {
            throw "Could not create new Disk - $($($_.Exception).Message)"
        }
    }
}