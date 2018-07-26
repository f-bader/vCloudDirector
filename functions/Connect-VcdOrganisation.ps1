function Connect-VcdOrganisation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Organisation,
        [Parameter(Mandatory = $true)][System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory = $true)][string]$APIurl,
        [Parameter(Mandatory = $false)][string]$APIVersion = "30.0"
    )

    try {
        #region Generate authentication string
        $AuthenticationString = $($Credential.UserName) + '@' + $Organisation + ':' + $($Credential.GetNetworkCredential().Password)
        $EncodedAuthenticationString = [System.Text.Encoding]::UTF8.GetBytes($AuthenticationString)
        Remove-Variable AuthenticationString
        $EncodedAuthenticationStringBase64 = [System.Convert]::ToBase64String($EncodedAuthenticationString)
        Write-Verbose "Generated encoded Authentication string"
        #endregion

        #region Get login URL
        $Uri = $APIurl + '/versions'
        $versions = Invoke-RestMethod -Uri $Uri -Method GET -ErrorAction Stop

        Write-Verbose "Looking for API Version $APIVersion"
        foreach ($VersionInfo in $versions.SupportedVersions.VersionInfo) {
            #$VersionInfo
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


        #region Generate session headers
        $headers = @{"Accept" = "application/*+xml;version=$APIVersion"}
        $headers += @{"Authorization" = "Basic $($EncodedAuthenticationStringBase64)"}
        Write-Verbose "Generated header"
        $SessionInformation = Invoke-WebRequest -Uri $loginUrl -Headers $headers -Method POST -SessionVariable vCoudSession -ErrorAction Stop -UseBasicParsing
        $headers = @{"Accept" = "application/*+xml;version=$APIVersion"}
        $headers += @{"x-vcloud-authorization" = $($SessionInformation.Headers.'x-vcloud-authorization')}
        if ($SessionInformation.Headers -eq 0 ) {
            throw "No header found"
        }
        #endregion

        #region
        Set-Variable -Name "GlobalvCDAPIUri" -Value $APIurl -Scope Global
        Set-Variable -Name "GlobalvCDSession" -Value $vCloudSession -Scope Global
        Set-Variable -Name "GlobalvCDHeaders" -Value $headers -Scope Global
        Return "Login to organisation $($SessionInformation.Session.org) with user $($SessionInformation.Session.user) successful"
        #endregion

    } catch {
        throw "Login failed - $($($_.Exception).Message)"
    }
}