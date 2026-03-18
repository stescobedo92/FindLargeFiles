@{
    # Module manifest for Find-LargeFiles

    # Script module file associated with this manifest
    RootModule        = 'Find-LargeFiles.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID              = 'a3f7b2c1-4d8e-4f6a-9b1c-3e5d7f8a2b4c'

    # Author of this module
    Author            = 'stesc'

    # Company or vendor of this module
    CompanyName       = 'stesc'

    # Copyright statement for this module
    Copyright         = '(c) 2026 stesc. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Finds the largest files in a directory and displays them in a formatted table with size in GB, MB, and source path. Useful for disk space analysis and cleanup.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Find-LargeFiles')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module for discoverability in the PowerShell Gallery
            Tags         = @('Files', 'DiskSpace', 'LargeFiles', 'Storage', 'Cleanup', 'Utility', 'FileSystem')

            # A URL to the license for this module
            LicenseUri   = 'https://github.com/stesc/FindLargeFiles/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri   = 'https://github.com/stesc/FindLargeFiles'

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Find-LargeFiles. Scans directories for the largest files and outputs a table with size in GB, MB, and source directory.'
        }
    }
}
