function Remove-VcdSnapshot {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string]$VM,
        [Parameter(Mandatory = $true)][string]$vAppName,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Session = $GlobalvCDSession
    )
    Begin {

    }
    Process {
        try {
            $VMXml = Get-VcdVM -Name $VM -vAppName $vAppName -Session $Session -APIurl $APIurl -ErrorAction Stop
            if ( ($VMXml | Measure-Object | Select-Object -ExpandProperty Count) -ne 1 ) {
                Write-Error "Found $($VMXml | Measure-Object | Select-Object -ExpandProperty Count) VMs. Abort." -ErrorAction Stop
            }

            if ($pscmdlet.ShouldProcess($VM, "Remove Snapshot")) {
                $Uri = $VMXml.href + "/action/removeAllSnapshots"

                $Task = Invoke-RestMethod -Uri $Uri -Method POST -WebSession $Session -ErrorAction Stop
                Write-Verbose $Task.Task.Operation
                if ($RunAsync.IsPresent) {
                    Return $Task.Task
                } else {
                    #region Wait until task completes
                    try {
                        do {
                            Start-Sleep 1
                            $Task = Invoke-RestMethod -Uri $Task.Task.href -Method GET -WebSession $Session
                            Write-Verbose $Task.Task.Operation
                        } until ($Task.Task.Status -eq 'success' -or $Task.Task.Status -eq 'error')
                        Return $Task.Task
                    } catch {
                        throw "Could not query task"
                    }
                    #endregion
                }
            }
        } catch {
            throw "Could not remove Snapshot - $($($_.Exception).Message)"
        }
    }
}