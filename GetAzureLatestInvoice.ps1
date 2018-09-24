Add-Type -Path ".\Tools\Microsoft.IdentityModel.Clients.ActiveDirectory\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

#
# Authentication and resource Url
#
$tenantId = "yourtenant.onmicrosoft.com" # or GUID "01234567-89AB-CDEF-0123-456789ABCDEF"
$clientId = "FEDCBA98-7654-3210-FEDC-BA9876543210"
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$resource = "https://management.azure.com"
$subscription = "0123ABCD-4567-89EF-0123-ABCD4567EF89"

#
# Authentication Url
#
$authUrl = "https://login.microsoftonline.com/$tenantId/" 

#
# Create AuthenticationContext for acquiring token 
# 
$authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext $authUrl

#
# Acquire the authentication result
#
$platformParameters = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList "Always"
$authResult = $authContext.AcquireTokenAsync($resource, $clientId, $redirectUri, $platformParameters).Result

if ($null -ne $authResult.AccessToken) {
    #
    # Compose the access token type and access token for authorization header
    #
    $headerParams = @{'Authorization' = "$($authResult.AccessTokenType) $($authResult.AccessToken)"}

    #
    # Get the most recent invoice
    #
    $url = "$resource/subscriptions/$subscription/providers/Microsoft.Billing/invoices/latest?api-version=2017-04-24-preview"
    $result = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
    
    if ($null -ne $result) {
        $invoiceJson = ($result.Content | ConvertFrom-Json)
        $invoiceUrl = $invoiceJson.properties.downloadUrl.url
        $invoiceStartDate = $invoiceJson.properties.invoicePeriodStartDate
        $invoiceEndDate = $invoiceJson.properties.invoicePeriodEndDate
        Invoke-WebRequest $invoiceUrl -OutFile "invoice-$invoiceStartDate-$invoiceEndDate.pdf"
    }
    else {
        Write-Host "ERROR: Failed to download invoice"
    }
}
else {
    Write-Host "ERROR: No Access Token"
}