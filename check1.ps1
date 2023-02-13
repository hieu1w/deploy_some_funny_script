# Import the AzureAD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Initialize the results array
$results = @()

# Check App registrations for HTTPS URLs and logout links
$appRegistrations = Get-AzureADApplication
foreach ($appRegistration in $appRegistrations) {
    $result = [ordered]@{
        'App Registration Name' = $appRegistration.DisplayName
        'HTTPS URL' = ($appRegistration.ReplyUrls[0] -match '^https://') -eq $True
        'Logout Link' = $False
    }
    # Check for a logout link in the reply URLs
    foreach ($replyUrl in $appRegistration.ReplyUrls) {
        if ($replyUrl -match 'logout') {
            $result['Logout Link'] = $True
            break
        }
    }
    $results += $result
}

# Check AAD groups for owners and high number of guest users
$groups = Get-AzureADGroup
foreach ($group in $groups) {
    # Check for owners
    $hasOwners = ($group.Owners.Count -gt 0)
    # Check for high number of guest users
    $guestUsers = Get-AzureADGroupMember -ObjectId $group.ObjectId | Where-Object { $_.UserType -eq "Guest" }
    $highGuestCount = ($guestUsers.Count -gt 50)
    $result = [ordered]@{
        'Group Name' = $group.DisplayName
        'Owners' = $hasOwners
        'High Number of Guest Users' = $highGuestCount
    }
    $results += $result
}

# Check for insecure guest user settings in Azure AD
$guestUsers = Get-AzureADUser -Filter "userType eq 'Guest'"
foreach ($guestUser in $guestUsers) {
    # Check for insecure settings (this would require additional logic and is just an example)
    $insecure = $False
    if ($guestUser.City -eq "Paris") {
        $insecure = $True
    }
    $result = [ordered]@{
        'Guest User' = $guestUser.DisplayName
        'Insecure Settings' = $insecure
    }
    $results += $result
}

# Add a check for unrestricted access to the admin portal (this would require additional logic and is just an example)
$adminRoleMembers = Get-AzureADDirectoryRoleMember -ObjectId "Company Administrator"
foreach ($member in $adminRoleMembers.Members) {
    $user = Get-AzureADUser -ObjectId $member.ObjectId
    if ($user.UserType -eq "Guest") {
        $result = [ordered]@{
            'User' = $user.DisplayName
            'Unrestricted Access' = $True
        }
        $results += $result
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "AuditResults.csv" -NoTypeInformation

# Send the results via email
Send-MailMessage -From "audit@example.com" -To "admin@example.com" -Subject "Audit Results" -Body "Attached is