# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubRepositoryTypeName = 'GitHub.Repository'
    GitHubRepositoryTopicTypeName = 'GitHub.RepositoryTopic'
    GitHubRepositoryContributorTypeName = 'GitHub.RepositoryContributor'
    GitHubRepositoryCollaboratorTypeName = 'GitHub.RepositoryCollaborator'
    GitHubRepositoryContributorStatisticsTypeName = 'GitHub.RepositoryContributorStatistics'
    GitHubRepositoryLanguageTypeName = 'GitHub.RepositoryLanguage'
    GitHubRepositoryTagTypeName = 'GitHub.RepositoryTag'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter New-GitHubRepository
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub.

    .DESCRIPTION
        Creates a new repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER RepositoryName
        Name of the repository to be created.

    .PARAMETER OrganizationName
        Name of the organization that the repository should be created under.
        If not specified, will be created under the current user's account.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER GitIgnoreTemplate
        Desired language or platform .gitignore template to apply.
        For supported values, call Get-GitHubGitIgnore.
        Values are case-sensitive.

    .PARAMETER LicenseTemplate
        Choose an open source license template that best suits your needs.
        For supported values, call Get-GitHubLicense
        Values are case-sensitive.

    .PARAMETER TeamId
        The id of the team that will be granted access to this repository.
        This is only valid when creating a repository in an organization.

    .PARAMETER Private
        By default, this repository will be created Public.  Specify this to create
        a private repository.

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER AutoInit
        Specify this to create an initial commit with an empty README.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DeleteBranchOnMerge
        Specifies the automatic deleting of head branches when pull requests are merged.

    .PARAMETER IsTemplate
        Specifies whether the repository is made available as a template.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -AutoInit

    .EXAMPLE
        'MyNewRepo' | New-GitHubRepository -AutoInit

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -Organization MyOrg -DisallowRebaseMerge
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $RepositoryName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $OrganizationName,

        [string] $Description,

        [string] $Homepage,

        [string] $GitIgnoreTemplate,

        [string] $LicenseTemplate,

        [int64] $TeamId,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $AutoInit,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [switch] $DeleteBranchOnMerge,

        [switch] $IsTemplate,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = 'user/repos'
    if ($PSBoundParameters.ContainsKey('OrganizationName') -and
        (-not [String]::IsNullOrEmpty($OrganizationName)))
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName
        $uriFragment = "orgs/$OrganizationName/repos"
    }

    if ($PSBoundParameters.ContainsKey('TeamId') -and (-not $PSBoundParameters.ContainsKey('OrganizationName')))
    {
        $message = 'TeamId may only be specified when creating a repository under an organization.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $hashBody = @{
        'name' = $RepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('GitIgnoreTemplate')) { $hashBody['gitignore_template'] = $GitIgnoreTemplate }
    if ($PSBoundParameters.ContainsKey('LicenseTemplate')) { $hashBody['license_template'] = $LicenseTemplate }
    if ($PSBoundParameters.ContainsKey('TeamId')) { $hashBody['team_id'] = $TeamId }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('AutoInit')) { $hashBody['auto_init'] = $AutoInit.ToBool() }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DeleteBranchOnMerge')) { $hashBody['delete_branch_on_merge'] = $DeleteBranchOnMerge.ToBool() }
    if ($PSBoundParameters.ContainsKey('IsTemplate')) { $hashBody['is_template'] = $IsTemplate.ToBool() }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'AcceptHeader' = $script:baptisteAcceptHeader
        'Description' = "Creating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter New-GitHubRepositoryFromTemplate
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub from a template repository.

    .DESCRIPTION
        Creates a new repository on GitHub from a template repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the template repository.
        If no value is specified, the DefaultOwnerName configuration property value will be used,
        and if there is no configuration value defined, the current authenticated user will be used.

    .PARAMETER RepositoryName
        Name of the template repository.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TargetOwnerName
        The organization or person who will own the new repository.
        To create a new repository in an organization, the authenticated user must be a member
        of the specified organization.

    .PARAMETER TargetRepositoryName
        Name of the repository to be created.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Private
        By default, this repository will created Public.  Specify this to create a private
        repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .NOTES
        The authenticated user must own or be a member of an organization that owns the repository.

        To check if a repository is available to use as a template, call `Get-GitHubRepository` on the
        repository in question and check that the is_template property is $true.

    .EXAMPLE
        New-GitHubRepositoryFromTemplate -OwnerName MyOrg -RepositoryName MyTemplateRepo -TargetRepositoryName MyNewRepo -TargetOwnerName Me

        Creates a new GitHub repository from the specified template repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName MyOrg -RepositoryName MyTemplateRepo
        $repo | New-GitHubRepositoryFromTemplate -TargetRepositoryName MyNewRepo -TargetOwnerName Me

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "",
        Justification="Methods called within here make use of PSShouldProcess, and the switch is
        passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Elements')]
        [ValidateNotNullOrEmpty()]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 2,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetOwnerName,

        [Parameter(
            Mandatory,
            Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetRepositoryName,

        [string] $Description,

        [switch] $Private,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        RepositoryName = (Get-PiiSafeString -PlainText $RepositoryName)
        OwnerName = (Get-PiiSafeString -PlainText $OwnerName)
        TargetRepositoryName = (Get-PiiSafeString -PlainText $TargetRepositoryName)
        TargetOwnerName = (Get-PiiSafeString -PlainText $TargetOwnerName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/generate"

    $hashBody = @{
        owner = $TargetOwnerName
        name = $TargetRepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating $TargetRepositoryName from Template"
        'AcceptHeader' = $script:baptisteAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue `
            -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Remove-GitHubRepository
{
<#
    .SYNOPSIS
        Removes/deletes a repository from GitHub.

    .DESCRIPTION
        Removes/deletes a repository from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubRepository -OwnerName You -RepositoryName YourRepoToDelete

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete -Confirm:$false

        Remove repository with the given URI, without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete -Force

        Remove repository with the given URI, without prompting for confirmation.

    .EXAMPLE
        $repo = Get-GitHubRepository -Uri https://github.com/You/YourRepoToDelete
        $repo | Remove-GitHubRepository -Force

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubRepository')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($RepositoryName, "Remove repository"))
    {
        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName"
            'Method' = 'Delete'
            'Description' = "Deleting $RepositoryName"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Get-GitHubRepository
{
<#
    .SYNOPSIS
        Retrieves information about a repository or list of repositories on GitHub.

    .DESCRIPTION
        Retrieves information about a repository or list of repositories on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER OrganizationName
        The name of the organization to retrieve the repositories for.

    .PARAMETER Visibility
        The type of visibility/accessibility for the repositories to return.

    .PARAMETER Affiliation
        Can be one or more of:

        owner - Repositories that are owned by the authenticated user

        collaborator - Repositories that the user has been added to as a collaborator

        organization_member - Repositories that the user has access to through being
        a member of an organization.  This includes every repository on every team that the user
        is on.

    .PARAMETER Type
        The type of repository to return.

    .PARAMETER Sort
        Property that the results should be sorted by

    .PARAMETER Direction
        Direction of the sort that is to be applied to the results.

    .PARAMETER GetAllPublicRepositories
        If this is specified with no other parameter, then instead of returning back all
        repositories for the current authenticated user, it will instead return back all
        public repositories on GitHub in the order in which they were created.

    .PARAMETER Since
        The ID of the last public repository that you have seen.  If specified with
        -GetAllPublicRepositories, will only return back public repositories created _after_ this
        one.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Get-GitHubRepository

        Gets all repositories for the current authenticated user.

    .EXAMPLE
        Get-GitHubRepository -GetAllPublicRepositories

        Gets all public repositories on GitHub.

    .EXAMPLE
        Get-GitHubRepository -OwnerName octocat

        Gets all of the repositories for the user octocat

    .EXAMPLE
        Get-GitHubUser -UserName octocat | Get-GitHubRepository

        Gets all of the repositories for the user octocat

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/microsoft/PowerShellForGitHub

        Gets information about the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        $repo | Get-GitHubRepository

        You can pipe in a previous repository to get its refreshed information.

    .EXAMPLE
        Get-GitHubRepository -OrganizationName PowerShell

        Gets all of the repositories in the PowerShell organization.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='AuthenticatedUser')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "",
        Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsOrUser')]
        [Alias('UserName')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsOrUser')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [string] $OrganizationName,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [ValidateSet('All', 'Public', 'Private')]
        [string] $Visibility,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [ValidateSet('Owner', 'Collaborator', 'OrganizationMember')]
        [string[]] $Affiliation,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('All', 'Owner', 'Public', 'Private', 'Member', 'Forks', 'Sources')]
        [string] $Type,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('Created', 'Updated', 'Pushed', 'FullName')]
        [string] $Sort,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [Parameter(ParameterSetName='PublicRepos')]
        [switch] $GetAllPublicRepositories,

        [Parameter(ParameterSetName='PublicRepos')]
        [int64] $Since,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    # We are explicitly disabling validation here because a valid parameter set for this function
    # allows the OwnerName to be passed in, but not the RepositoryName.  That would allow the caller
    # to get all of the repositories owned by a specific username.  Therefore, we don't want to fail
    # if both have not been supplied...we'll do the extra validation within the function.
    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'UsageType' = $PSCmdlet.ParameterSetName
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    switch ($PSCmdlet.ParameterSetName)
    {
        'ElementsOrUser' {
            # This is a little tricky.  Ideally we'd have two separate ParameterSets (Elements, User),
            # however PowerShell would be unable to disambiguate between the two, so unfortunately
            # we need to do some additional work here.  And because fallthru doesn't appear to be
            # working right, we're combining both of those.

            if ([String]::IsNullOrWhiteSpace($OwnerName))
            {
                $message = 'OwnerName could not be determined.'
                Write-Log -Message $message -Level Error
                throw $message
            }
            elseif ([String]::IsNullOrWhiteSpace($RepositoryName))
            {
                $telemetryProperties['UsageType'] = 'User'
                $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName

                $uriFragment = "users/$OwnerName/repos"
                $description = "Getting repos for $OwnerName"
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('Type') -or
                    $PSBoundParameters.ContainsKey('Sort') -or
                    $PSBoundParameters.ContainsKey('Direction'))
                {
                    $message = 'Unable to specify -Type, -Sort and/or -Direction when retrieving a specific repository.'
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $telemetryProperties['UsageType'] = 'Elements'
                $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
                $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

                $uriFragment = "repos/$OwnerName/$RepositoryName"
                $description = "Getting $OwnerName/$RepositoryName"
            }

            break
        }

        'Uri' {
            if ($PSBoundParameters.ContainsKey('Type') -or
                $PSBoundParameters.ContainsKey('Sort') -or
                $PSBoundParameters.ContainsKey('Direction'))
            {
                $message = 'Unable to specify -Type, -Sort and/or -Direction when retrieving a specific repository.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
            $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

            $uriFragment = "repos/$OwnerName/$RepositoryName"
            $description = "Getting $OwnerName/$RepositoryName"

            break
        }

        'Organization' {
            $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

            $uriFragment = "orgs/$OrganizationName/repos"
            $description = "Getting repos for $OrganizationName"

            break
        }

        'AuthenticatedUser' {
            if ($PSBoundParameters.ContainsKey('Type') -and
                ($PSBoundParameters.ContainsKey('Visibility') -or
                $PSBoundParameters.ContainsKey('Affiliation')))
            {
                $message = 'Unable to specify -Type when using -Visibility and/or -Affiliation.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $uriFragment = 'user/repos'
            $description = 'Getting repos for current authenticated user'

            break
        }

        'PublicRepos' {
            $uriFragment = 'repositories'
            $description = "Getting all public repositories"

            if ($PSBoundParameters.ContainsKey('Since'))
            {
                $description += " since $Since"
            }

            break
        }
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Pushed' = 'pushed'
        'FullName' = 'full_name'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @()
    if ($PSBoundParameters.ContainsKey('Visibility')) { $getParams += "visibility=$($Visibility.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Sort')) { $getParams += "sort=$($sortConverter[$Sort])" }
    if ($PSBoundParameters.ContainsKey('Type')) { $getParams += "type=$($Type.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Direction')) { $getParams += "direction=$($directionConverter[$Direction])" }
    if ($PSBoundParameters.ContainsKey('Affiliation') -and $Affiliation.Count -gt 0)
    {
        $affiliationMap = @{
            Owner = 'owner'
            Collaborator = 'collaborator'
            OrganizationMember = 'organization_member'
        }
        $affiliationParam = @()

        foreach ($member in $Affiliation)
        {
            $affiliationParam += $affiliationMap[$member]
        }
        $getParams += "affiliation=$($affiliationParam -join ',')"
    }
    if ($PSBoundParameters.ContainsKey('Since')) { $getParams += "since=$Since" }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' = $description
        'AcceptHeader' = "$script:nebulaAcceptHeader,$script:baptisteAcceptHeader,$script:mercyAcceptHeader"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Rename-GitHubRepository
{
<#
    .SYNOPSIS
        Rename a GitHub repository

    .DESCRIPTION
        Renames a GitHub repository with the new name provided.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository to rename. You can supply this directly, or more easily by
        using Get-GitHubRepository to get the repository as you please,
        and then piping the result to this cmdlet.

    .PARAMETER NewName
        The new name to set for the given GitHub repository

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Get-GitHubRepository -Owner octocat -RepositoryName hello-world | Rename-GitHubRepository -NewName hello-again-world

        Get the given 'hello-world' repo from the user 'octocat' and then
        rename it to be https://github.com/octocat/hello-again-world.

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/octocat/hello-world | Rename-GitHubRepository -NewName hello-again-world -Confirm:$false

        Get the repository at https://github.com/octocat/hello-world and then
        rename it https://github.com/octocat/hello-again-world.
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world.

    .EXAMPLE
        New-GitHubRepositoryFork -Uri https://github.com/octocat/hello-world | Foreach-Object {$_ | Rename-GitHubRepository -NewName "$($_.name)_fork"}

        Fork the `hello-world` repository from the user 'octocat', and then
        rename the newly forked repository by appending '_fork'.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world -Confirm:$false

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world without prompting for confirmation.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world -Force

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world without prompting for confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Uri',
        ConfirmImpact="High")]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias("RepositoryUrl")]
        [string] $Uri,

        [parameter(Mandatory)]
        [String] $NewName,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    # This method was created by mistake and is now retained to avoid a breaking change.
    # Set-GitHubRepository is able to handle this scenario just fine.
    return Set-GitHubRepository @PSBoundParameters
}

filter Set-GitHubRepository
{
<#
    .SYNOPSIS
        Updates the details of an existing repository on GitHub.

    .DESCRIPTION
        Updates the details of an existing repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER NewName
        Rename the repository to this new name.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER DefaultBranch
        Update the default branch for this repository.

    .PARAMETER Private
        Specify this to make the repository private.
        To change a repository to be public, specify -Private:$false

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DeleteBranchOnMerge
        Specifies the automatic deleting of head branches when pull requests are merged.

    .PARAMETER IsTemplate
        Specifies whether the repository is made available as a template.

    .PARAMETER Archived
        Specify this to archive this repository.
        NOTE: You cannot unarchive repositories through the API / this module.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution
        when renaming the repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Set-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub -Description 'The best way to automate your GitHub interactions'

        Changes the description of the specified repository.

    .EXAMPLE
        Set-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub -Private:$false

        Changes the visibility of the specified repository to be public.

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub |
            Set-GitHubRepository -NewName 'PoShForGitHub' -Force

        Renames the repository without any user confirmation prompting.  This is identical to using
        Rename-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub -NewName 'PoShForGitHub' -Confirm:$false
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact='High')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Alias('Update-GitHubRepository')] # Non-standard usage of the Update verb, but done to avoid a breaking change post 0.14.0
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [ValidateNotNullOrEmpty()]
        [string] $NewName,

        [string] $Description,

        [string] $Homepage,

        [string] $DefaultBranch,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [switch] $DeleteBranchOnMerge,

        [switch] $IsTemplate,

        [switch] $Archived,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('NewName'))
    {
        $existingName = if ($PSCmdlet.ParameterSetName -eq 'Uri') { $Uri } else { $OwnerName, $RepositoryName -join '/' }
        if (-not $PSCmdlet.ShouldProcess($existingName, "Rename repository to '$NewName'"))
        {
            return
        }

        $hashBody['name'] = $NewName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $hashBody['default_branch'] = $DefaultBranch }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DeleteBranchOnMerge')) { $hashBody['delete_branch_on_merge'] = $DeleteBranchOnMerge.ToBool() }
    if ($PSBoundParameters.ContainsKey('IsTemplate')) { $hashBody['is_template'] = $IsTemplate.ToBool() }
    if ($PSBoundParameters.ContainsKey('Archived')) { $hashBody['archived'] = $Archived.ToBool() }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'AcceptHeader' = $script:baptisteAcceptHeader
        'Description' = "Updating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Get-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Retrieves information about a repository on GitHub.

    .DESCRIPTION
        Retrieves information about a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryTopic

    .EXAMPLE
        Get-GitHubRepositoryTopic -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryTopicTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
        'Method' = 'Get'
        'Description' = "Getting topics for $RepositoryName"
        'AcceptHeader' = $script:mercyAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTopicTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

function Set-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Replaces all topics for a repository on GitHub.

    .DESCRIPTION
        Replaces all topics for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Topic
        Array of topics to add to the repository.

    .PARAMETER Clear
        Specify this to clear all topics from the repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryTopic

    .EXAMPLE
        Set-GitHubRepositoryTopic -OwnerName microsoft -RepositoryName PowerShellForGitHub -Clear

    .EXAMPLE
        Set-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub -Topic ('octocat', 'powershell', 'github')

    .EXAMPLE
        ('octocat', 'powershell', 'github') | Set-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub

    .NOTES
        This is implemented as a function rather than a filter because the ValueFromPipeline
        parameter (Topic) is itself an array which we want to ensure is processed only a single time.
        This API endpoint doesn't add topics to a repository, it replaces the existing topics with
        the new set provided, so we need to make sure that we have all the requested topics available
        to us at the time that the API endpoint is called.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsName')]
    [OutputType({$script:GitHubRepositoryTopicTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriName')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriClear')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='ElementsName')]
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='UriName')]
        [Alias('Name')]
        [string[]] $Topic,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsClear')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriClear')]
        [switch] $Clear,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    begin
    {
        $topics = @()
    }

    process
    {
        foreach ($value in $Topic)
        {
            $topics += $value
        }
    }

    end
    {
        Write-InvocationLog -Invocation $MyInvocation

        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
            'Clear' = $PSBoundParameters.ContainsKey('Clear')
        }

        if ($Clear)
        {
            $description = "Clearing topics in $RepositoryName"
        }
        else
        {
            $description = "Replacing topics in $RepositoryName"
        }

        $hashBody = @{
            'names' = $topics
        }

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Put'
            'Description' = $description
            'AcceptHeader' = $script:mercyAcceptHeader
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return (Invoke-GHRestMethod @params |
            Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTopicTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
    }
}

filter Get-GitHubRepositoryContributor
{
<#
    .SYNOPSIS
        Retrieve list of contributors for a given repository.

    .DESCRIPTION
        Retrieve list of contributors for a given repository.

        GitHub identifies contributors by author email address.
        This groups contribution counts by GitHub user, which includes all associated email addresses.
        To improve performance, only the first 500 author email addresses in the repository link to
        GitHub users. The rest will appear as anonymous contributors without associated GitHub user
        information.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER IncludeAnonymousContributors
        If specified, anonymous contributors will be included in the results.

    .PARAMETER IncludeStatistics
        If specified, each result will include statistics for the number of additions, deletions
        and commit counts, by week (excluding merge commits and empty commits).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.User
        GitHub.RepositoryContributorStatistics

    .EXAMPLE
        Get-GitHubRepositoryContributor -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets a list of contributors for the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryContributor -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -IncludeStatistics

        Gets a list of contributors for the PowerShellForGithub repository including statistics.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryContributorTypeName})]
    [OutputType({$script:GitHubRepositoryContributorStatisticsTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [switch] $IncludeAnonymousContributors,

        [switch] $IncludeStatistics,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'IncludeAnonymousContributors' = $IncludeAnonymousContributors.ToBool()
        'IncludeStatistics' = $IncludeStatistics.ToBool()
    }

    $getParams = @()
    if ($IncludeAnonymousContributors) { $getParams += 'anon=true' }

    $uriFragment = "repos/$OwnerName/$RepositoryName/contributors"
    if ($IncludeStatistics) { $uriFragment = "repos/$OwnerName/$RepositoryName/stats/contributors" }

    $params = @{
        'UriFragment' = $uriFragment + '?' + ($getParams -join '&')
        'Description' = "Getting contributors for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $results = Invoke-GHRestMethodMultipleResult @params

    if ($IncludeStatistics)
    {
        foreach ($item in $results)
        {
            $item.PSObject.TypeNames.Insert(0, $script:GitHubRepositoryContributorStatisticsTypeName)

            if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
            {
                $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.author
            }
        }
    }
    else
    {
        $results = $results | Add-GitHubRepositoryContributorAdditionalProperties
    }

    return $results
}

filter Get-GitHubRepositoryCollaborator
{
<#
    .SYNOPSIS
        Retrieve list of collaborators for a given repository.

    .DESCRIPTION
        Retrieve list of collaborators for a given repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER Affiliation
        Filter collaborators returned by their affiliation. Can be one of:
           All:     All collaborators the authenticated user can see.
           Direct:  All collaborators with permissions to an organization-owned repository,
                     regardless of organization membership status.
           Outside: All outside collaborators of an organization-owned repository.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets a list of collaborators for the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

        Gets a list of collaborators for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryCollaboratorTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [ValidateSet('All', 'Direct', 'Outside')]
        [string] $Affiliation = 'All',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $getParams = @(
        "affiliation=$($Affiliation.ToLower())"
    )

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/collaborators?" + ($getParams -join '&')
        'Description' = "Getting collaborators for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryCollaboratorAdditionalProperties)
}

filter Get-GitHubRepositoryLanguage
{
<#
    .SYNOPSIS
        Retrieves a list of the programming languages used in a repository on GitHub.

    .DESCRIPTION
        Retrieves a list of the programming languages used in a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryLanguage - The value shown for each language is the number
        of bytes of code written in that language.

    .EXAMPLE
        Get-GitHubRepositoryLanguage -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryLanguage -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryLanguageTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/languages"
        'Description' = "Getting languages for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryLanguageTypeName)
}

filter Get-GitHubRepositoryTag
{
<#
    .SYNOPSIS
        Retrieves tags for a repository on GitHub.

    .DESCRIPTION
        Retrieves tags for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryTag

    .EXAMPLE
        Get-GitHubRepositoryTag -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTag -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryTagTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/tags"
        'Description' = "Getting tags for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTagTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Move-GitHubRepositoryOwnership
{
<#
    .SYNOPSIS
        Changes the ownership of a repository on GitHub.

    .DESCRIPTION
        Changes the ownership of a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER NewOwnerName
        The username or organization name the repository will be transferred to.

    .PARAMETER TeamId
        ID of the team or teams to add to the repository.  Teams can only be added to
        organization-owned repositories.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Move-GitHubRepositoryOwnership -OwnerName microsoft -RepositoryName PowerShellForGitHub -NewOwnerName OctoCat
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Alias('Transfer-GitHubRepositoryOwnership')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NewOwnerName,

        [int64[]] $TeamId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $hashBody = @{
        'new_owner' = $NewOwnerName
    }

    if ($TeamId.Count -gt 0) { $hashBody['team_ids'] = @($TeamId) }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/transfer"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Transferring ownership of $RepositoryName to $NewOwnerName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Test-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Retrieves the status of vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Retrieves the status of vulnerability alerts for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        System.Boolean

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Test-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Retrieves the status of vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Test-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Retrieves the status of vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
        Description = "Getting Vulnerability Alerts status for $RepositoryName"
        AcceptHeader = $script:dorianAcceptHeader
        Method = 'Get'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
        NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters `
            -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try
    {
        Invoke-GHRestMethod @params | Out-Null
        $result = $true
    }
    catch
    {
        # Temporary code to handle current differences in exception object between PS5 and PS7
        if ($PSVersionTable.PSedition -eq 'Core')
        {
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and
                ($_.ErrorDetails.Message | ConvertFrom-Json).message -eq 'Vulnerability alerts are disabled.')
            {
                $result = $false
            }
            else
            {
                throw $_
            }
        }
        else
        {
            if ($_.Exception.Message -like '*Vulnerability alerts are disabled.*')
            {
                $result = $false
            }
            else
            {
                throw $_
            }
        }
    }

    return $result
}

filter Enable-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Enables vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Enables vulnerability alerts for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Enable-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Enables vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Enable-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Enables vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSCmdlet.ShouldProcess($RepositoryName, 'Enable Vulnerability Alerts'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
            Description =  "Enabling Vulnerability Alerts for $RepositoryName"
            AcceptHeader = $script:dorianAcceptHeader
            Method = 'Put'
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params | Out-Null
    }
}

filter Disable-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Disables vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Disables vulnerability alerts for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Disable-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Disables vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Disable-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Disables vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSCmdlet.ShouldProcess($RepositoryName, 'Disable Vulnerability Alerts'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
            Description =  "Disabling Vulnerability Alerts for $RepositoryName"
            AcceptHeader = $script:dorianAcceptHeader
            Method = 'Delete'
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params | Out-Null
    }
}

filter Enable-GitHubRepositorySecurityFix
{
 <#
    .SYNOPSIS
        Enables automated security fixes for a repository on GitHub.

    .DESCRIPTION
        Enables automated security fixes for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Enable-GitHubRepositorySecurityFix -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Enables automated security fixes for the PowerShellForGitHub repository.
    .EXAMPLE
        Enable-GitHubRepositorySecurityFix -Uri https://github.com/PowerShell/PowerShellForGitHub

        Enables automated security fixes for the PowerShellForGitHub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSCmdlet.ShouldProcess($RepositoryName, 'Enable Automated Security Fixes'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/automated-security-fixes"
            Description =  "Enabling Automated Security Fixes for $RepositoryName"
            AcceptHeader = $script:londonAcceptHeader
            Method = 'Put'
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params
    }
}

filter Disable-GitHubRepositorySecurityFix
{
 <#
    .SYNOPSIS
        Disables automated security fixes for a repository on GitHub.

    .DESCRIPTION
        Disables automated security fixes for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Disable-GitHubRepositorySecurityFix -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Disables automated security fixes for the PowerShellForGithub repository.
    .EXAMPLE
        Disable-GitHubRepositorySecurityFix -Uri https://github.com/PowerShell/PowerShellForGitHub

        Disables automated security fixes for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSCmdlet.ShouldProcess($RepositoryName, 'Disable Automated Security Fixes'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/automated-security-fixes"
            Description =  "Disabling Automated Security Fixes for $RepositoryName"
            AcceptHeader = $script:londonAcceptHeader
            Method = 'Delete'
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params | Out-Null
    }
}

filter Add-GitHubRepositoryAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Repository
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryTypeName,

        [string] $OwnerName,

        [string] $RepositoryName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = [String]::Empty
            if ([String]::IsNullOrEmpty($item.html_url))
            {
                if ($PSBoundParameters.ContainsKey('OwnerName') -and
                    $PSBoundParameters.ContainsKey('RepositoryName'))
                {
                    $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                }
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
            }

            if (-not [String]::IsNullOrEmpty($repositoryUrl))
            {
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            if ($item.id -gt 0)
            {
                Add-Member -InputObject $item -Name 'RepositoryId' -Value $item.id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.owner)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.owner
            }

            if ($null -ne $item.organization)
            {
                $null = Add-GitHubOrganizationAdditionalProperties -InputObject $item.organization
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubRepositoryContributorAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Contributor objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER Name
        The name of the Contributor.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER Id
        The ID of the Contributor.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryContributor
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryContributorTypeName,

        [string] $Name,

        [int64] $Id
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)
        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $UserName = $item.login
            if ([String]::IsNullOrEmpty($UserName) -and $PSBoundParameters.ContainsKey('Name'))
            {
                $UserName = $Name
            }

            if (-not [String]::IsNullOrEmpty($UserName))
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserName'
                    Value = $UserName
                    MemberType = 'NoteProperty'
                    Force = $true
                }
                Add-Member @addMemberParms
            }

            $UserId = $item.id
            if (($UserId -eq 0) -and $PSBoundParameters.ContainsKey('Id'))
            {
                $UserId = $Id
            }

            if ($UserId -ne 0)
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserId'
                    Value = $UserId
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubRepositoryCollaboratorAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Collaborator objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER Name
        The name of the Collaborator.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER Id
        The ID of the Collaborator.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryCollaborator
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryCollaboratorTypeName,

        [string] $Name,

        [int64] $Id
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $userName = $item.login
            if ([String]::IsNullOrEmpty($userName) -and $PSBoundParameters.ContainsKey('Name'))
            {
                $userName = $Name
            }

            if (-not [String]::IsNullOrEmpty($userName))
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserName'
                    Value = $userName
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }

            $userId = $item.id
            if (($userId -eq 0) -and $PSBoundParameters.ContainsKey('Id'))
            {
                $userId = $Id
            }

            if ($userId -ne 0)
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserId'
                    Value = $userId
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }
        }

        Write-Output $item
    }
}
