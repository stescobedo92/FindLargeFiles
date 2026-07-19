# Find-LargeFiles

[![CI](https://github.com/stescobedo92/FindLargeFiles/actions/workflows/ci.yml/badge.svg)](https://github.com/stescobedo92/FindLargeFiles/actions/workflows/ci.yml)
[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-blue.svg)](LICENSE)
[![Publish Version](https://img.shields.io/powershellgallery/v/Find-LargeFiles?label=Publish%20Version)](https://www.powershellgallery.com/packages/Find-LargeFiles)
[![Release](https://img.shields.io/github/v/release/stescobedo92/FindLargeFiles?label=Release)](https://github.com/stescobedo92/FindLargeFiles/releases)

Find-LargeFiles is a PowerShell module that scans a directory for the largest files and displays them in a formatted table with size in GB, MB, and the source path where they were found.
It is useful for disk space analysis, storage cleanup, and identifying space-consuming files across your file system.

The canonical cmdlet is `Find-LargeFile`. The previous `Find-LargeFiles` command is still exported as a compatibility alias.

## Minimum PowerShell version

5.1

## Installation Options

### Install Module

```powershell
Install-Module -Name Find-LargeFiles
```

### Install PSResource

```powershell
Install-PSResource -Name Find-LargeFiles
```

## Usage

### Find the 10 largest files in the current directory

```powershell
Find-LargeFile
```

### Search a specific path and return the top 20

```powershell
Find-LargeFile -Path "C:\Users" -Top 20
```

### Only files larger than 500 MB

```powershell
Find-LargeFile -Path "D:\" -MinimumSizeMB 500
```

### Search without recursion

```powershell
Find-LargeFile -Path "C:\" -Top 5 -Recurse:$false
```

### Include hidden and system files

```powershell
Find-LargeFile -Path "C:\Users" -Force
```

### Filter by extension

```powershell
Find-LargeFile -Path "C:\Repos" -Extension iso, vhdx, bak -Top 15
```

### Exclude noisy directories

```powershell
Find-LargeFile -Path "C:\Dev" -Exclude '*\node_modules\*', '*\.git\*' -Depth 4
```

### Find large files that have not changed recently

```powershell
Find-LargeFile -Path "C:\Logs" -OlderThan (Get-Date).AddDays(-30) -MinimumSizeMB 100
```

### Sample Output

```
FileName          SizeGB   SizeMB   SourceDirectory
--------          ------   ------   ---------------
database.bak       4.200  4300.80   C:\Backups
vm-disk.vhdx       2.100  2150.40   C:\VMs
installer.iso      1.500  1536.00   C:\Downloads
logs-archive.zip   0.800   819.20   C:\Logs
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-Path` | String | Current directory | Root directory to search |
| `-Top` | Int | 10 | Number of largest files to return |
| `-Recurse` | Switch | `$true` | Include subdirectories |
| `-Depth` | Int | (unlimited) | Maximum subdirectory levels to search |
| `-MinimumSizeMB` | Double | 0 | Minimum file size filter in MB |
| `-Include` | String[] | | Wildcard patterns matched against file names (`*.iso`) |
| `-Extension` | String[] | | File extensions to include (`iso`, `.bak`) |
| `-Exclude` | String[] | | Wildcard patterns matched against full paths |
| `-OlderThan` | DateTime | | Only files with `LastWriteTime` older than this value |
| `-NewerThan` | DateTime | | Only files with `LastWriteTime` newer than this value |
| `-Force` | Switch | `$false` | Include hidden and system files |

During long scans, progress is reported with `Write-Progress`.

## Output Properties

| Property | Description |
|---|---|
| `FileName` | Name of the file |
| `SizeGB` | File size in gigabytes (3 decimal places) |
| `SizeMB` | File size in megabytes (2 decimal places) |
| `SourceDirectory` | Directory where the file is located |
| `FullPath` | Full file path |
| `LastWriteTime` | Last modification date |
| `Extension` | File extension (including the leading dot) |

## License

This project is licensed under the [MIT License](LICENSE).
