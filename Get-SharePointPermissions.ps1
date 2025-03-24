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
[CmdletBinding()]
[OutputType([PSCustomObject])]
param
( 
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$SiteCollectionUrl
) # param block
begin
{
    # Define a custom object to hold SharePoint permissions
    class SharePointPermission {
        [string]$Url
        [string]$Type
        [string]$UserName
        [string]$PermissionLevel
    
        SharePointPermission([string]$url, [string]$type, [string]$userName, [string]$permissionLevel) {
            $this.Url = $url
            $this.Type = $type
            $this.UserName = $userName
            $this.PermissionLevel = $permissionLevel
        }
    }

    # Function to log messages
    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]$LogFile = "$env:TEMP\SharePointPermissions.log"
        )
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "$timestamp - $Message"

        Write-Host $logMessage
        Add-Content -Path $LogFile -Value $logMessage
    }
}
} # begin block
process
{
    function Get-SharePointPermissions 
    {
        [CmdletBinding()]
        param 
        (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [string]$SiteCollectionUrl
        ) # param block
    
        process 
        {
            $headers = @{ "Accept" = "application/json;odata=verbose" }
    
            # Get Site Collection Administrators
            try 
            {
                $siteAdmins = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/siteusers" -Headers $headers -UseDefaultCredentials
                $siteAdmins = $siteAdmins.d.results | Where-Object { $_.IsSiteAdmin -eq $true }
    
                foreach ($admin in $siteAdmins) 
                {
                    [SharePointPermission]::new($SiteCollectionUrl, "Site Collection Administrator", $admin.LoginName, "Full Control")
                    Write-Log -Message "Found Site Collection Administrator: $($admin.LoginName)"
                } # foreach ($admin in $siteAdmins)
            } # try block
            catch 
            {
                Write-Log -Message "Error retrieving site collection administrators: $($_.Exception.Message)"
            } # catch block
    
            # Get all webs with unique permissions
            try 
            {
                $webs = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/webs" -Headers $headers -UseDefaultCredentials
                $webs = $webs.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }
    
                foreach ($web in $webs) 
                {
                    [SharePointPermission]::new($web.Url, "Web with Unique Permissions", "", "")
                    Write-Log -Message "Found Web with Unique Permissions: $($web.Url)"
                } # foreach ($web in $webs)
            } # try block
            catch 
            {
                Write-Log -Message "Error retrieving webs: $($_.Exception.Message)"
            } # catch block
    
            # Get lists with unique permissions
            try 
            {
                $lists = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists" -Headers $headers -UseDefaultCredentials
                $lists = $lists.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }
    
                foreach ($list in $lists) 
                {
                    [SharePointPermission]::new($list.DefaultViewUrl, "List with Unique Permissions", "", "")
                    Write-Log -Message "Found List with Unique Permissions: $($list.DefaultViewUrl)"
                } # foreach ($list in $lists)
            } 
            catch 
            {
                Write-Log -Message "Error retrieving lists: $($_.Exception.Message)"
            } # catch block
    
            # Get list items with unique permissions
            foreach ($list in $lists) 
            {
                try 
                {
                    $items = Invoke-RestMethod -Uri "$SiteCollectionUrl/_api/web/lists(guid'$($list.Id)')/items" -Headers $headers -UseDefaultCredentials
                    $items = $items.d.results | Where-Object { $_.HasUniqueRoleAssignments -eq $true }
    
                    foreach ($item in $items) 
                    {
                        [SharePointPermission]::new($item.FileRef, "List Item with Unique Permissions", "", "")
                        Write-Log -Message "Found List Item with Unique Permissions: $($item.FileRef)"
                    } # foreach ($item in $items)
                } # try block
                catch 
                {
                    Write-Log -Message "Error retrieving items for list $($list.Title): $($_.Exception.Message)"
                } # catch block
            } # foreach ($list in $lists)
        } # process block
    } # function Get-SharePointPermissions 
    
} # process block
end
{

} # end block

