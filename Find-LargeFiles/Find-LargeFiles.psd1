@{
    # Module manifest for Find-LargeFiles

    # Script module file associated with this manifest
    RootModule        = 'Find-LargeFiles.psm1'

    # Version number of this module
    ModuleVersion     = '1.2.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID              = 'a3f7b2c1-4d8e-4f6a-9b1c-3e5d7f8a2b4c'

    # Author of this module
    Author            = 'stescobedo'

    # Company or vendor of this module
    CompanyName       = 'stescobedo'

    # Copyright statement for this module
    Copyright         = '(c) 2026 stescobedo. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Finds the largest files in a directory and displays them in a formatted table with size in GB, MB, and source path. Useful for disk space analysis and cleanup.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Find-LargeFile')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @('Find-LargeFiles')

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module for discoverability in the PowerShell Gallery
            Tags         = @('Files', 'DiskSpace', 'LargeFiles', 'Storage', 'Cleanup', 'Utility', 'FileSystem')

            # A URL to the license for this module
            LicenseUri   = 'https://github.com/stescobedo92/FindLargeFiles/blob/master/LICENSE'

            # A URL to the main website for this project
            ProjectUri   = 'https://github.com/stescobedo92/FindLargeFiles'

            # ReleaseNotes of this module
            ReleaseNotes = 'Adds Include/Extension/Exclude filters, Depth-limited recursion, OlderThan/NewerThan date filters, scan progress via Write-Progress, and an Extension property on result objects.'
        }
    }
}
