# LogInsight
# https://192.168.100.111/rest-api#Getting-started-with-the-Log-Insight-REST-API


###############################################################
# Handle Authentication
###############################################################
$vLIServer = "192.168.100.111"     # Primary node

# $vLIProvider is Local or ActiveDirectory
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
#$NewVersion = "8.6.0-18703301"
$NewVersion = "8.6.2-19092412"


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
    $CurrentVersion = $JSON.Version
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan 'Version'
$CurrentVersion
Write-Host -ForegroundColor White '---'


################################################
# Log Insight Upgrades - Upgrades
################################################
$URL = $vLIBaseURL+"upgrades"

Try
{
    $JSON = Invoke-RestMethod -Method GET -Uri $URL -Headers $vLISessionHeader -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan '/upgrades GET'
Write-Host 'Version    :' $JSON.version
Write-Host 'fullVersion:' $JSON.fullversion
Write-Host 'stable     :' $JSON.stable
Write-Host 'nodes      :' $JSON.nodes
Write-Host -ForegroundColor White '---'


################################################
# Log Insight Upgrades - Upgrades/local
################################################
$URL = $vLIBaseURL+"upgrades/local"

Try
{
    $JSON = Invoke-RestMethod -Method GET -Uri $URL -Headers $vLISessionHeader -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan '/upgrades/local GET'
Write-Host 'Version    :' $JSON.version
Write-Host 'fullVersion:' $JSON.fullversion
Write-Host -ForegroundColor White '---'


################################################
# Log Insight Upgrades - Upgrades/CurrentVersion
################################################
$URL = $vLIBaseURL+"upgrades/$CurrentVersion"

Try
{
    $JSON = Invoke-RestMethod -Method GET -Uri $URL -Headers $vLISessionHeader -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan '/upgrades/'$CurrentVersion
$JSON.status


################################################
# Log Insight Upgrades - Upgrades/NewVersion
################################################
$URL = $vLIBaseURL+"upgrades/$NewVersion"

Try
{
    $JSON = Invoke-RestMethod -Method GET -Uri $URL -Headers $vLISessionHeader -ContentType $Type
}
Catch
{
    $_.Exception.ToString()
    $error[0] | Format-List -Force
}
Write-Host -ForegroundColor Cyan '/upgrades/'$NewVersion
$JSON.status

#EOF



