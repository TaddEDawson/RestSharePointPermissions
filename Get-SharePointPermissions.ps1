<#
.SYNOPSIS
Retrieves SharePoint permissions and logs results.

.DESCRIPTION
Use this function to gather information about site collection administrators, webs, lists, and items with unique permissions.

.PARAMETER SiteCollectionUrl
The URL of the SharePoint site collection.

.EXAMPLE
Get-SharePointPermissions -SiteCollectionUrl "https://yoursharepointsite"

.NOTES
Author: (Your Name)
#>
function Get-SharePointPermissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SiteCollectionUrl
    )

    $headers = @{
        "Accept" = "application/json;odata=verbose"
    }

    # Get Site Collection Administrators
    try {
        $siteAdmins = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/siteusers" -Headers $headers -UseDefaultCredentials
        $siteAdmins = $siteAdmins.d.results | Where-Object { $_.IsSiteAdmin -eq $true }

        foreach ($admin in $siteAdmins) {
            [SharePointPermission]::new($SiteCollectionUrl, "Site Collection Administrator", $admin.LoginName, "Full Control")
            Write-Log -Message "Found Site Collection Administrator: $($admin.LoginName)"
        }
    } catch {
        Write-Log -Message "Error retrieving site collection administrators: $($_.Exception.Message)"
    }

    # Get all webs with unique permissions
    try {
        $webs = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/webs" -Headers $headers -UseDefaultCredentials
        $webs = $webs.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

        foreach ($web in $webs) {
            [SharePointPermission]::new($web.Url, "Web with Unique Permissions", "", "")
            Write-Log -Message "Found Web with Unique Permissions: $($web.Url)"
        }
    } catch {
        Write-Log -Message "Error retrieving webs: $($_.Exception.Message)"
    }

    # Get lists with unique permissions
    try {
        $lists = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists" -Headers $headers -UseDefaultCredentials
        $lists = $lists.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

        foreach ($list in $lists) {
            [SharePointPermission]::new($list.DefaultViewUrl, "List with Unique Permissions", "", "")
            Write-Log -Message "Found List with Unique Permissions: $($list.DefaultViewUrl)"
        }
    } catch {
        Write-Log -Message "Error retrieving lists: $($_.Exception.Message)"
    }

    # Get list items with unique permissions
    foreach ($list in $lists) {
        try {
            $items = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists(guid'$($list.Id)')/items" -Headers $headers -UseDefaultCredentials
            $items = $items.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

            foreach ($item in $items) {
                [SharePointPermission]::new($item.FileRef, "List Item with Unique Permissions", "", "")
                Write-Log -Message "Found List Item with Unique Permissions: $($item.FileRef)"
            }
        } catch {
            Write-Log -Message "Error retrieving items for list $($list.Title): $($_.Exception.Message)"
        }
    }
}
