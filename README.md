# Find-LargeFiles

Find-LargeFiles is a PowerShell module that scans a directory for the largest files and displays them in a formatted table with size in GB, MB, and the source path where they were found.
It is useful for disk space analysis, storage cleanup, and identifying space-consuming files across your file system.

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
Find-LargeFiles
```

### Search a specific path and return the top 20

```powershell
Find-LargeFiles -Path "C:\Users" -Top 20
```

### Only files larger than 500 MB

```powershell
Find-LargeFiles -Path "D:\" -MinimumSizeMB 500
```

### Search without recursion

```powershell
Find-LargeFiles -Path "C:\" -Top 5 -Recurse:$false
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
| `-MinimumSizeMB` | Double | 0 | Minimum file size filter in MB |

## Output Properties

| Property | Description |
|---|---|
| `FileName` | Name of the file |
| `SizeGB` | File size in gigabytes (3 decimal places) |
| `SizeMB` | File size in megabytes (2 decimal places) |
| `SourceDirectory` | Directory where the file is located |
| `FullPath` | Full file path |
| `LastWriteTime` | Last modification date |

## Owners

- [stesc](https://github.com/stesc)

## Copyright

(c) 2026 stesc. All rights reserved.

## License

This project is licensed under the [MIT License](LICENSE).
