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

    .PARAMETER Depth
        Limits how many subdirectory levels to recurse. When specified, overrides unlimited recursion.

    .PARAMETER MinimumSizeMB
        Filters results to only include files larger than the specified size in megabytes.

    .PARAMETER Include
        One or more wildcard patterns matched against file names (for example *.iso, *.bak).

    .PARAMETER Extension
        One or more file extensions to include (with or without a leading dot). Example: iso, vhdx, .bak.

    .PARAMETER Exclude
        One or more wildcard patterns matched against the full path. Matching files are skipped.
        Example: *\node_modules\*, *\.git\*, *\Windows\WinSxS\*

    .PARAMETER OlderThan
        Only include files whose LastWriteTime is older than this date/time.

    .PARAMETER NewerThan
        Only include files whose LastWriteTime is newer than this date/time.

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

    .EXAMPLE
        Find-LargeFile -Path "C:\Repos" -Extension iso, vhdx, bak -Top 15

        Finds the largest ISO, VHDX, and BAK files under C:\Repos.

    .EXAMPLE
        Find-LargeFile -Path "C:\Dev" -Exclude '*\node_modules\*', '*\.git\*' -Depth 4

        Scans up to 4 levels deep and skips node_modules and .git directories.

    .EXAMPLE
        Find-LargeFile -Path "C:\Logs" -OlderThan (Get-Date).AddDays(-30) -MinimumSizeMB 100

        Finds large log files that have not been written to in the last 30 days.

    .INPUTS
        System.String
            You can pipe a directory path to Find-LargeFile.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
            Returns objects with FileName, SizeGB, SizeMB, and SourceDirectory properties.

    .NOTES
        Author: stescobedo
        Version: 1.2.0
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

        [Parameter(HelpMessage = 'Maximum subdirectory depth to search.')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Depth,

        [Parameter(HelpMessage = 'Minimum file size in megabytes to include in results.')]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$MinimumSizeMB = 0,

        [Parameter(HelpMessage = 'Wildcard patterns matched against file names.')]
        [string[]]$Include,

        [Parameter(HelpMessage = 'File extensions to include (with or without a leading dot).')]
        [Alias('Ext')]
        [string[]]$Extension,

        [Parameter(HelpMessage = 'Wildcard patterns matched against full paths to exclude.')]
        [string[]]$Exclude,

        [Parameter(HelpMessage = 'Only include files older than this date/time.')]
        [datetime]$OlderThan,

        [Parameter(HelpMessage = 'Only include files newer than this date/time.')]
        [datetime]$NewerThan,

        [Parameter(HelpMessage = 'Include hidden and system files in the search.')]
        [switch]$Force
    )

    begin {
        if ($PSBoundParameters.ContainsKey('OlderThan') -and $PSBoundParameters.ContainsKey('NewerThan') -and $NewerThan -ge $OlderThan) {
            throw [System.ArgumentException]::new('NewerThan must be earlier than OlderThan when both filters are specified.')
        }

        $normalizedExtensions = @()
        if ($Extension) {
            $normalizedExtensions = @(
                $Extension | ForEach-Object {
                    $value = $_.Trim()
                    if ([string]::IsNullOrWhiteSpace($value)) {
                        return
                    }
                    if ($value.StartsWith('.')) {
                        $value.ToLowerInvariant()
                    }
                    else {
                        ('.' + $value).ToLowerInvariant()
                    }
                }
            )
        }

        $includePatterns = @()
        if ($Include) {
            $includePatterns = @($Include | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }

        $excludePatterns = @()
        if ($Exclude) {
            $excludePatterns = @($Exclude | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }

        Write-Verbose "Starting search for the $Top largest files."
    }

    process {
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $rootPath = $resolvedPath.ProviderPath

        Write-Verbose "Searching in: $rootPath"

        $getChildItemParams = @{
            LiteralPath = $rootPath
            File        = $true
            ErrorAction = 'SilentlyContinue'
        }

        $shouldRecurse = -not $PSBoundParameters.ContainsKey('Recurse') -or $Recurse.IsPresent
        $hasDepth = $PSBoundParameters.ContainsKey('Depth')

        if ($hasDepth) {
            $getChildItemParams['Depth'] = $Depth
        }
        elseif ($shouldRecurse) {
            $getChildItemParams['Recurse'] = $true
        }

        if ($Force) {
            $getChildItemParams['Force'] = $true
        }

        $minimumSizeBytes = $MinimumSizeMB * 1MB
        $hasOlderThan = $PSBoundParameters.ContainsKey('OlderThan')
        $hasNewerThan = $PSBoundParameters.ContainsKey('NewerThan')
        $activity = "Finding large files in $rootPath"
        $enumerated = 0
        $matched = 0
        $candidates = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

        try {
            Get-ChildItem @getChildItemParams | ForEach-Object {
                $enumerated++

                if (($enumerated % 250) -eq 0) {
                    Write-Progress -Activity $activity -Status "Scanned $enumerated files; $matched candidates" -PercentComplete -1
                }

                if ($_.Length -lt $minimumSizeBytes) {
                    return
                }

                if ($hasOlderThan -and $_.LastWriteTime -ge $OlderThan) {
                    return
                }

                if ($hasNewerThan -and $_.LastWriteTime -le $NewerThan) {
                    return
                }

                if ($normalizedExtensions.Count -gt 0 -and $normalizedExtensions -notcontains $_.Extension.ToLowerInvariant()) {
                    return
                }

                if ($includePatterns.Count -gt 0) {
                    $nameMatched = $false
                    foreach ($pattern in $includePatterns) {
                        if ($_.Name -like $pattern) {
                            $nameMatched = $true
                            break
                        }
                    }
                    if (-not $nameMatched) {
                        return
                    }
                }

                if ($excludePatterns.Count -gt 0) {
                    foreach ($pattern in $excludePatterns) {
                        if ($_.FullName -like $pattern) {
                            return
                        }
                    }
                }

                $matched++
                $candidates.Add($_)
            }
        }
        finally {
            Write-Progress -Activity $activity -Completed
        }

        Write-Verbose "Scanned $enumerated files; $matched matched filters before Top selection."

        if ($candidates.Count -eq 0) {
            Write-Warning "No files found in '$rootPath' that match the current filters."
            return
        }

        $files = $candidates |
            Sort-Object -Property Length -Descending |
            Select-Object -First $Top

        foreach ($file in $files) {
            [PSCustomObject]@{
                PSTypeName      = 'FindLargeFiles.Result'
                FileName        = $file.Name
                SizeGB          = [math]::Round($file.Length / 1GB, 3)
                SizeMB          = [math]::Round($file.Length / 1MB, 2)
                SourceDirectory = $file.DirectoryName
                FullPath        = $file.FullName
                LastWriteTime   = $file.LastWriteTime
                Extension       = $file.Extension
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
