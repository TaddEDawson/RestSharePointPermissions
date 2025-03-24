class SharePointPermission {
    [string]$URL
    [string]$Type
    [string]$UserLogin
    [string]$RoleAssignments

    SharePointPermission([string]$url, [string]$type, [string]$userLogin, [string]$roleAssignments) {
        $this.URL = $url
        $this.Type = $type
        $this.UserLogin = $userLogin
        $this.RoleAssignments = $roleAssignments
    }
}

function Get-SharePointPermissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SiteCollectionUrl
    )

    $headers = @{
        "Accept" = "application/json;odata=verbose"
    }

    # Get Site Collection Administrators
    $siteAdmins = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/siteusers" -Headers $headers -UseDefaultCredentials
    $siteAdmins = $siteAdmins.d.results | Where-Object { $_.IsSiteAdmin -eq $true }

    foreach ($admin in $siteAdmins) {
        [SharePointPermission]::new($SiteCollectionUrl, "Site Collection Administrator", $admin.LoginName, "Full Control")
    }

    # Get all webs with unique permissions
    $webs = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/webs" -Headers $headers -UseDefaultCredentials
    $webs = $webs.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

    foreach ($web in $webs) {
        [SharePointPermission]::new($web.Url, "Web with Unique Permissions", "", "")
    }

    # Get lists with unique permissions
    $lists = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists" -Headers $headers -UseDefaultCredentials
    $lists = $lists.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

    foreach ($list in $lists) {
        [SharePointPermission]::new($list.DefaultViewUrl, "List with Unique Permissions", "", "")
    }

    # Get list items with unique permissions
    foreach ($list in $lists) {
        $items = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists(guid'$($list.Id)')/items" -Headers $headers -UseDefaultCredentials
        $items = $items.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

        foreach ($item in $items) {
            [SharePointPermission]::new($item.FileRef, "List Item with Unique Permissions", "", "")
        }
    }
}

# Example usage
# Get-SharePointPermissions -SiteCollectionUrl "https://yoursharepointsite"