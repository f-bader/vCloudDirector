function Connect-VcdOrganisation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Organisation,
        [Parameter(Mandatory = $true)][System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory = $true)][string]$APIurl,
        [Parameter(Mandatory = $false)][string]$APIVersion = "5.1"
    )

    try {
        #region Generate encoded Authentication string
        $AuthenticationString = $($Credential.UserName) + '@' + $Organisation + ':' + $($Credential.GetNetworkCredential().Password)
        $EncodedAuthenticationString = [System.Text.Encoding]::UTF8.GetBytes($AuthenticationString)
        Remove-Variable AuthenticationString
        $EncodedAuthenticationStringBase64 = [System.Convert]::ToBase64String($EncodedAuthenticationString)
        Write-Verbose "Generated encoded Authentication string"
        #endregion

        #region Define REST header
        $headers = @{"Accept" = "application/*+xml;version=$APIVersion"}
        Write-Verbose "Generated header"
        #endregion

        #region Get Login Url
        $Uri = $APIurl + '/versions'
        $versions = Invoke-RestMethod -Uri $Uri -Headers $headers -Method GET -ErrorAction Stop

        Write-Verbose "Looking for API Version $APIVersion"
        foreach ($VersionInfo in $versions.SupportedVersions.VersionInfo) {
            if ($VersionInfo.Version -eq $APIVersion) {
                $loginUrl = $VersionInfo.LoginUrl
                Write-Verbose "Login Url: $loginUrl"
                break
            }
        }

        if ([string]::IsNullOrEmpty($loginUrl)) {
            throw "No Login URL Available - Exit"
        }
        #endregion

        #region Login and generate Session
        # Add Authorization to header
        $headers += @{"Authorization" = "Basic $($EncodedAuthenticationStringBase64)"}
        $SessionInformation = Invoke-RestMethod -Uri $loginurl -Headers $headers -Method POST -Session vCloudSession -ErrorAction Stop
        if ($vCloudSession.Headers.Count -eq 0 ) {
            throw "No header found"
        }
        #endregion

        #region
        Set-Variable -Name "GlobalvCDAPIUri" -Value $APIurl -Scope Global
        Set-Variable -Name "GlobalvCDSession" -Value $vCloudSession -Scope Global
        Return "Login to organisation $($SessionInformation.Session.org) with user $($SessionInformation.Session.user) successful"
        #endregion

    } catch {
        throw "Login failed - $($($_.Exception).Message)"
    }
}