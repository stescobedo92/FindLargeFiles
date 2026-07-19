BeforeAll {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Find-LargeFiles\Find-LargeFiles.psd1'
    Import-Module -Name $modulePath -Force
}

Describe 'Find-LargeFiles' {
    BeforeAll {
        # Create a temporary directory with test files
        $testRoot = Join-Path -Path $TestDrive -ChildPath 'TestFiles'
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

        $subDir = Join-Path -Path $testRoot -ChildPath 'SubFolder'
        New-Item -Path $subDir -ItemType Directory -Force | Out-Null

        # Create files of known sizes
        $sizes = @(
            @{ Name = 'small.txt';   Bytes = 1KB }
            @{ Name = 'medium.txt';  Bytes = 500KB }
            @{ Name = 'large.txt';   Bytes = 2MB }
            @{ Name = 'bigger.txt';  Bytes = 10MB }
            @{ Name = 'biggest.txt'; Bytes = 50MB }
        )

        foreach ($file in $sizes) {
            $filePath = Join-Path -Path $testRoot -ChildPath $file.Name
            $bytes = New-Object byte[] $file.Bytes
            [System.IO.File]::WriteAllBytes($filePath, $bytes)
        }

        # Create a file in the subdirectory
        $subFilePath = Join-Path -Path $subDir -ChildPath 'nested.txt'
        $bytes = New-Object byte[] 5MB
        [System.IO.File]::WriteAllBytes($subFilePath, $bytes)

        $hiddenFilePath = Join-Path -Path $testRoot -ChildPath 'hidden-large.bin'
        $bytes = New-Object byte[] 20MB
        [System.IO.File]::WriteAllBytes($hiddenFilePath, $bytes)
        $hiddenFile = Get-Item -LiteralPath $hiddenFilePath
        $hiddenFile.Attributes = $hiddenFile.Attributes -bor [System.IO.FileAttributes]::Hidden

        # Extra fixtures for Include / Extension / Exclude / Depth / date filters
        $nodeModules = Join-Path -Path $testRoot -ChildPath 'node_modules'
        New-Item -Path $nodeModules -ItemType Directory -Force | Out-Null
        $excludedPath = Join-Path -Path $nodeModules -ChildPath 'vendor.pack'
        $bytes = New-Object byte[] 30MB
        [System.IO.File]::WriteAllBytes($excludedPath, $bytes)

        $deepDir = Join-Path -Path $testRoot -ChildPath 'Level1\Level2\Level3'
        New-Item -Path $deepDir -ItemType Directory -Force | Out-Null
        $deepFilePath = Join-Path -Path $deepDir -ChildPath 'deep.bin'
        $bytes = New-Object byte[] 8MB
        [System.IO.File]::WriteAllBytes($deepFilePath, $bytes)

        $isoPath = Join-Path -Path $testRoot -ChildPath 'installer.iso'
        $bytes = New-Object byte[] 12MB
        [System.IO.File]::WriteAllBytes($isoPath, $bytes)

        $oldFilePath = Join-Path -Path $testRoot -ChildPath 'old-archive.bak'
        $bytes = New-Object byte[] 15MB
        [System.IO.File]::WriteAllBytes($oldFilePath, $bytes)
        (Get-Item -LiteralPath $oldFilePath).LastWriteTime = (Get-Date).AddDays(-60)

        $newFilePath = Join-Path -Path $testRoot -ChildPath 'fresh-data.bak'
        $bytes = New-Object byte[] 14MB
        [System.IO.File]::WriteAllBytes($newFilePath, $bytes)
        (Get-Item -LiteralPath $newFilePath).LastWriteTime = Get-Date
    }

    Context 'Default behavior' {
        It 'Exports the canonical cmdlet and compatibility alias' {
            Get-Command -Name Find-LargeFile -CommandType Function | Should -Not -BeNullOrEmpty
            Get-Command -Name Find-LargeFiles -CommandType Alias | Should -Not -BeNullOrEmpty
        }

        It 'Returns files sorted by size descending' {
            $result = Find-LargeFiles -Path $testRoot
            $result[0].FileName | Should -Be 'biggest.txt'
            $result[1].FileName | Should -Be 'vendor.pack'
        }

        It 'Returns the correct number of files' {
            $result = Find-LargeFiles -Path $testRoot -Top 100
            # 5 root txt + nested + iso + deep + 2 bak + vendor.pack (hidden excluded)
            $result.Count | Should -Be 11
        }

        It 'Includes files from subdirectories by default' {
            $result = Find-LargeFiles -Path $testRoot
            $result.FileName | Should -Contain 'nested.txt'
        }
    }

    Context 'Top parameter' {
        It 'Limits results to the specified count' {
            $result = Find-LargeFiles -Path $testRoot -Top 3
            $result.Count | Should -Be 3
        }

        It 'Returns the largest files when limited' {
            $result = Find-LargeFiles -Path $testRoot -Top 1
            $result[0].FileName | Should -Be 'biggest.txt'
        }
    }

    Context 'Recurse parameter' {
        It 'Excludes subdirectories when Recurse is false' {
            $result = Find-LargeFiles -Path $testRoot -Recurse:$false
            $result.FileName | Should -Not -Contain 'nested.txt'
        }
    }

    Context 'MinimumSizeMB parameter' {
        It 'Filters files below the minimum size' {
            $result = Find-LargeFiles -Path $testRoot -MinimumSizeMB 5
            $result | ForEach-Object {
                $_.SizeMB | Should -BeGreaterOrEqual 5
            }
        }
    }

    Context 'Force parameter' {
        It 'Excludes hidden files by default' {
            $result = Find-LargeFiles -Path $testRoot
            $result.FileName | Should -Not -Contain 'hidden-large.bin'
        }

        It 'Includes hidden files when Force is used' {
            $result = Find-LargeFiles -Path $testRoot -Force
            $result.FileName | Should -Contain 'hidden-large.bin'
        }
    }

    Context 'Include and Extension parameters' {
        It 'Filters by Include wildcard patterns' {
            $result = Find-LargeFile -Path $testRoot -Include '*.iso'
            $result.Count | Should -Be 1
            $result[0].FileName | Should -Be 'installer.iso'
        }

        It 'Filters by Extension with or without a leading dot' {
            $result = Find-LargeFile -Path $testRoot -Extension bak, .iso
            $result.FileName | Should -Contain 'old-archive.bak'
            $result.FileName | Should -Contain 'fresh-data.bak'
            $result.FileName | Should -Contain 'installer.iso'
            $result.FileName | Should -Not -Contain 'biggest.txt'
        }
    }

    Context 'Exclude parameter' {
        It 'Skips files matching Exclude path wildcards' {
            $result = Find-LargeFile -Path $testRoot -Exclude '*\node_modules\*'
            $result.FileName | Should -Not -Contain 'vendor.pack'
            $result.FileName | Should -Contain 'biggest.txt'
        }
    }

    Context 'Depth parameter' {
        It 'Limits recursion depth' {
            $result = Find-LargeFile -Path $testRoot -Depth 1
            $result.FileName | Should -Contain 'nested.txt'
            $result.FileName | Should -Not -Contain 'deep.bin'
        }

        It 'Includes deeper files when Depth allows it' {
            $result = Find-LargeFile -Path $testRoot -Depth 3
            $result.FileName | Should -Contain 'deep.bin'
        }
    }

    Context 'Date filters' {
        It 'Returns only files older than OlderThan' {
            $result = Find-LargeFile -Path $testRoot -Extension bak -OlderThan (Get-Date).AddDays(-30)
            $result.FileName | Should -Contain 'old-archive.bak'
            $result.FileName | Should -Not -Contain 'fresh-data.bak'
        }

        It 'Returns only files newer than NewerThan' {
            $result = Find-LargeFile -Path $testRoot -Extension bak -NewerThan (Get-Date).AddDays(-7)
            $result.FileName | Should -Contain 'fresh-data.bak'
            $result.FileName | Should -Not -Contain 'old-archive.bak'
        }

        It 'Throws when NewerThan is not earlier than OlderThan' {
            {
                Find-LargeFile -Path $testRoot `
                    -NewerThan (Get-Date) `
                    -OlderThan (Get-Date).AddDays(-1)
            } | Should -Throw
        }
    }

    Context 'Output properties' {
        It 'Returns objects with expected properties' {
            $result = Find-LargeFiles -Path $testRoot -Top 1
            $result | Get-Member -Name 'FileName' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SizeGB' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SizeMB' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SourceDirectory' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'FullPath' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'LastWriteTime' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'Extension' | Should -Not -BeNullOrEmpty
        }

        It 'Calculates SizeMB correctly' {
            $result = Find-LargeFiles -Path $testRoot -Top 1
            $result[0].SizeMB | Should -BeGreaterOrEqual 47
        }
    }

    Context 'Error handling' {
        It 'Throws when path does not exist' {
            { Find-LargeFiles -Path 'C:\NonExistent\Path\12345' } | Should -Throw
        }

        It 'Shows a warning when no files are found' {
            $emptyDir = Join-Path -Path $TestDrive -ChildPath 'EmptyDir'
            New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
            Find-LargeFiles -Path $emptyDir -WarningVariable warn 3>$null
            $warn | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module -Name Find-LargeFiles -Force -ErrorAction SilentlyContinue
}
