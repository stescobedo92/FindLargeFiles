function Find-LargeFile {
    <#
    .SYNOPSIS
        Finds the largest files in a directory and displays them in a formatted table.

    .DESCRIPTION
        The Find-LargeFile function scans a specified directory (recursively by default)
        and returns the top N largest files. Results include file size in GB and MB,
        along with the source path where each file was found.

    .PARAMETER Path
        Specifies the root directory to search. Defaults to the current directory.

    .PARAMETER Top
        Specifies the number of largest files to return. Defaults to 10.

    .PARAMETER Recurse
        Indicates that the search should include all subdirectories. Enabled by default.

    .PARAMETER MinimumSizeMB
        Filters results to only include files larger than the specified size in megabytes.

    .PARAMETER Force
        Includes hidden and system files in the search.

    .EXAMPLE
        Find-LargeFile

        Finds the 10 largest files in the current directory and all subdirectories.

    .EXAMPLE
        Find-LargeFile -Path "C:\Users" -Top 20

        Finds the 20 largest files under C:\Users.

    .EXAMPLE
        Find-LargeFile -Path "D:\Data" -MinimumSizeMB 500

        Finds the 10 largest files under D:\Data that are at least 500 MB.

    .EXAMPLE
        Find-LargeFile -Path "C:\" -Top 5 -Recurse:$false

        Finds the 5 largest files in the root of C:\ without scanning subdirectories.

    .EXAMPLE
        Find-LargeFile -Path "C:\Users" -Force

        Finds the 10 largest files under C:\Users, including hidden and system files.

    .INPUTS
        System.String
            You can pipe a directory path to Find-LargeFile.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
            Returns objects with FileName, SizeGB, SizeMB, and SourceDirectory properties.

    .NOTES
        Author: stescobedo
        Version: 1.1.0
        Requires PowerShell 5.1 or later.

    .LINK
        https://github.com/stescobedo92/FindLargeFiles
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Directory path to search for large files.'
        )]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Container)) {
                throw "The path '$_' does not exist or is not a directory."
            }
            return $true
        })]
        [Alias('Directory', 'Folder')]
        [string]$Path = (Get-Location).Path,

        [Parameter(HelpMessage = 'Number of largest files to return.')]
        [ValidateRange(1, 1000)]
        [int]$Top = 10,

        [Parameter(HelpMessage = 'Search subdirectories recursively.')]
        [switch]$Recurse,

        [Parameter(HelpMessage = 'Minimum file size in megabytes to include in results.')]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$MinimumSizeMB = 0,

        [Parameter(HelpMessage = 'Include hidden and system files in the search.')]
        [switch]$Force
    )

    begin {
        Write-Verbose "Starting search for the $Top largest files."
    }

    process {
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop

        Write-Verbose "Searching in: $resolvedPath"

        $getChildItemParams = @{
            LiteralPath = $resolvedPath.ProviderPath
            File        = $true
            ErrorAction = 'SilentlyContinue'
        }

        $shouldRecurse = -not $PSBoundParameters.ContainsKey('Recurse') -or $Recurse.IsPresent

        if ($shouldRecurse) {
            $getChildItemParams['Recurse'] = $true
        }

        if ($Force) {
            $getChildItemParams['Force'] = $true
        }

        $minimumSizeBytes = $MinimumSizeMB * 1MB

        $files = Get-ChildItem @getChildItemParams |
            Where-Object { $_.Length -ge $minimumSizeBytes } |
            Sort-Object -Property Length -Descending |
            Select-Object -First $Top

        if (-not $files) {
            Write-Warning "No files found in '$($resolvedPath.ProviderPath)' that match the current filters."
            return
        }

        foreach ($file in $files) {
            [PSCustomObject]@{
                PSTypeName      = 'FindLargeFiles.Result'
                FileName        = $file.Name
                SizeGB          = [math]::Round($file.Length / 1GB, 3)
                SizeMB          = [math]::Round($file.Length / 1MB, 2)
                SourceDirectory = $file.DirectoryName
                FullPath        = $file.FullName
                LastWriteTime   = $file.LastWriteTime
            }
        }
    }

    end {
        Write-Verbose "Search complete."
    }
}

$defaultDisplaySet = 'FileName', 'SizeGB', 'SizeMB', 'SourceDirectory'
Update-TypeData -TypeName 'FindLargeFiles.Result' -DefaultDisplayPropertySet $defaultDisplaySet -Force

Set-Alias -Name Find-LargeFiles -Value Find-LargeFile

Export-ModuleMember -Function Find-LargeFile -Alias Find-LargeFiles
