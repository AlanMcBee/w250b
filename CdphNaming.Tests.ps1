BeforeAll {
    Remove-Module CdphNaming -ErrorAction SilentlyContinue
    Import-Module .\CdphNaming.psm1
}

Describe 'New-CdphResourceName' {
    BeforeEach {
        $defaultSplattingArgs = @{
            Arm_ResourceProvider     = ''
            Cdph_Organization        = 'ITSD'
            Cdph_BusinessUnit        = '123'
            Cdph_BusinessUnitProgram = '1234567'
            Cdph_Environment         = 'Dev'
            Cdph_ResourceInstance    = 1
        }
    }

    Context 'Key Vault' {
        BeforeEach {
            $defaultSplattingArgs.Arm_ResourceProvider = 'Microsoft.KeyVault/vaults'
        }

        Context 'When the input is valid' {
            It 'Should return a valid Key Vault resource name with too-long names truncated' {
                $keyVaultName = New-CdphResourceName @defaultSplattingArgs
                $keyVaultName | Should -BeExactly 'kv-ITSD-123-123456-Dev01'
            }

            It 'Should return a valid Key Vault resource name with short names' {
                $defaultSplattingArgs.Cdph_BusinessUnit = '12'
                $defaultSplattingArgs.Cdph_BusinessUnitProgram = '123'
                $keyVaultName = New-CdphResourceName @defaultSplattingArgs
                $keyVaultName | Should -BeExactly 'kv-ITSD-12-123-Dev-01'
            }

            It 'Should drop the final hyphen without truncating the program name' {
                $defaultSplattingArgs.Cdph_BusinessUnitProgram = '123456'
                $keyVaultName = New-CdphResourceName @defaultSplattingArgs
                $keyVaultName | Should -BeExactly 'kv-ITSD-123-123456-Dev01'
            }
        }

        Context 'When the input is bad: Organization' {
            It 'Should require a valid organization' {
                { 
                    $defaultSplattingArgs.Cdph_Organization = ''
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }
        }

        Context 'When the input is bad: Business Unit' {
            It 'Should require a business unit' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnit = ''
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a minimum length of 2' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnit = '1'
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a maximum length of 5' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnit = '123456'
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }
        }

        Context 'When the input is bad: Business Unit Program' {
            It 'Should require a business unit program' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnitProgram = ''
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a minimum length of 2' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnitProgram = '1'
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a maximum length of 7' {
                { 
                    $defaultSplattingArgs.Cdph_BusinessUnitProgram = '12345678'
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }
        }

        Context 'When the input is bad: Environment' {
            It 'Should require an environment' {
                { 
                    $defaultSplattingArgs.Cdph_Environment = ''
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }
            It 'Should require a valid environment' {
                { 
                    $defaultSplattingArgs.Cdph_Environment = 'Development'
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw
            }
        }

        Context 'When the input is good: Environment' {
            It 'Should allow a long environment name' {
                $defaultSplattingArgs.Cdph_Environment = 'Stage'
                $keyVaultName = New-CdphResourceName @defaultSplattingArgs
                $keyVaultName | Should -BeExactly 'kv-ITSD-123-1234-Stage01'
            }
        }

        Context 'When the input is bad: Resource Instance' {
            It 'Should require a resource instance' {
                { 
                    $defaultSplattingArgs.Cdph_ResourceInstance = $null
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a minimum value of 1' {
                { 
                    $defaultSplattingArgs.Cdph_ResourceInstance = 0
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }

            It 'Should require a maximum value of 99' {
                { 
                    $defaultSplattingArgs.Cdph_ResourceInstance = 100
                    New-CdphResourceName @defaultSplattingArgs
                } | Should -Throw 
            }
        }
    }
    Context 'Storage' {
        BeforeEach {
            $defaultSplattingArgs.Arm_ResourceProvider = 'Microsoft.Storage/storageAccounts'
        }

        Context 'When the input is valid' {
            It 'Should return a valid Storage resource name' {
                $storageName = New-CdphResourceName @defaultSplattingArgs
                $storageName | Should -BeExactly 'stitsd1231234567dev01'
            }

            It 'Should return a valid Storage resource name with too-long names truncated' {
                $defaultSplattingArgs.Cdph_BusinessUnit = '12345'
                $defaultSplattingArgs.Cdph_BusinessUnitProgram = '1234567'
                $defaultSplattingArgs.Cdph_Environment = 'Stage'
                $storageName = New-CdphResourceName @defaultSplattingArgs
                $storageName | Should -BeExactly 'stitsd12345123456stage01'
            }

            It 'Should return a valid Storage resource name with short names' {
                $defaultSplattingArgs.Cdph_BusinessUnit = '12'
                $defaultSplattingArgs.Cdph_BusinessUnitProgram = '123'
                $storageName = New-CdphResourceName @defaultSplattingArgs
                $storageName | Should -BeExactly 'stitsd12123dev01'
            }
                
        }
    }
}