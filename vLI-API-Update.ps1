# LogInsight
# Upgrade Log Insight using REST API, demo code

###############################################################
# Handle Authentication
###############################################################
$vLIServer = "192.168.100.111"     # Primary node

# $vLIProvider is local or ActiveDirectory
$vLIProvider = "Local"
# $vLIProvider = "ActiveDirectory"

# Prompting for credentials, collect $vLIUser and vLIPassword
#$Credentials = Get-Credential -Credential $null
#$vLIUser = $Credentials.UserName
#$Credentials.Password | ConvertFrom-SecureString
#$vLIPassword = $Credentials.GetNetworkCredential().password

# The easy way, DO NOT use outside lab!
$vLIUser     = 'admin'
$vLIPassword = 'VMware1!'


################################################
# Upgrade to version
################################################
#$version = "8.6.0-18703301"
$version = "8.6.2-19092412"


################################################
# Adding certificate exception to prevent API errors
################################################
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'


################################################
# Building API string & invoking REST API
################################################
$vLIBaseAuthURL = "https://" + $vLIServer + ":9543/api/v1/sessions"
$vLIBaseURL = "https://" + $vLIServer + ":9543/api/v1/"

$Type = "application/json"

# Creating JSON for Auth Body
$vLIAuthJSON =
"{
  ""username"": ""$vLIUser"",
  ""password"": ""$vLIPassword"",
  ""provider"": ""$vLIProvider""
}"
# Authenticating with API
Try
{
    $vLISessionResponse = Invoke-RestMethod -Method POST -Uri $vLIBaseAuthURL -Body $vLIAuthJSON -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
$vLISessionHeader = @{"Authorization"="Bearer "+$vLISessionResponse.SessionId}
Write-Host -ForegroundColor White '---'


################################################
# Building API string & invoking REST API,
# Log Insight Version
################################################
$URL = $vLIBaseURL+"version"

Try
{
    $JSON = Invoke-RestMethod -Method GET -Uri $URL -Headers $vLISessionHeader -ContentType $Type
    $LIVersion = $JSON.Version
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan 'Version'
$LIVersion
Write-Host -ForegroundColor White '---'


################################################
# Log Insight Upgrades - Upload pakfile
################################################
$version = "8.6.0-18703301"
$URL = $vLIBaseURL+"upgrades"

$JSONBody =
"{
  ""pakUrl"": ""http://192.168.100.90:8000/vmware/VMware-vRealize-Log-Insight-$version.pak""
}"

Try
{
    $JSON = Invoke-RestMethod -Method POST -Uri $URL -Headers $vLISessionHeader -Body $JSONBody -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan '.PAK file uploaded'


################################################
# Log Insight Upgrades - Start upgrade
################################################
$URL = $vLIBaseURL+"upgrades/$Version/eula"

$JSONBody =
"{
  ""accepted"": ""true""
}"

Try
{
    $JSON = Invoke-RestMethod -Method PUT -Uri $URL -Headers $vLISessionHeader -Body $JSONBody -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}

Write-Host -ForegroundColor Cyan 'Upgrade Started. Wait until node reconnects.'

#EOF
