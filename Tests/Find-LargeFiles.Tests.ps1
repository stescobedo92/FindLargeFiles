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
    }

    Context 'Default behavior' {
        It 'Returns files sorted by size descending' {
            $result = Find-LargeFiles -Path $testRoot
            $result[0].FileName | Should -Be 'biggest.txt'
            $result[1].FileName | Should -Be 'bigger.txt'
        }

        It 'Returns the correct number of files' {
            $result = Find-LargeFiles -Path $testRoot
            $result.Count | Should -Be 6
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

    Context 'Output properties' {
        It 'Returns objects with expected properties' {
            $result = Find-LargeFiles -Path $testRoot -Top 1
            $result | Get-Member -Name 'FileName' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SizeGB' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SizeMB' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'SourceDirectory' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'FullPath' | Should -Not -BeNullOrEmpty
            $result | Get-Member -Name 'LastWriteTime' | Should -Not -BeNullOrEmpty
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
