# Implement your module commands in this script.

$script:PSModuleRoot = $PSScriptRoot

# All exported functions - 600ms
foreach ($function in (Get-ChildItem "$script:PSModuleRoot\functions\*.ps1")) {
    . $function.FullName
    Export-ModuleMember -Function $function.BaseName
}

Set-Variable -Name "GlobalvCDAPIUri" -Value "" -Scope Global -Visibility Private
Set-Variable -Name "GlobalvCDSession" -Value "" -Scope Global -Visibility Private