function Wait-VcdTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TaskId,
        [Parameter(Mandatory = $false)][ValidateNotNull()][string]$APIurl = $GlobalvCDAPIUri,
        [Parameter(Mandatory = $false)][ValidateNotNull()]$Headers = $GlobalvCDHeaders
    )
    Process {
        try {
            do {
                Start-Sleep 1
                $Task = Get-VcdTask -TaskId $TaskId
                Write-Verbose $Task.Operation
            } until ($Task.Status -eq 'success' -or $Task.Status -eq 'error')
            Return $Task
        } catch {
            throw "Could not query task"
        }
    }
}