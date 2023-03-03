BeforeAll {
    Import-Module .\CdphNaming.psm1
}

Describe 'New-KeyVaultResourceName' {
    Context 'When the input is valid' {
        It 'Should return a valid Key Vault resource name with too-long names' {
            $keyVaultName = New-KeyVaultResourceName `
                -Cdph_Organization 'ITSD' `
                -Cdph_BusinessUnit '123' `
                -Cdph_BusinessUnitProgram '1234567' `
                -Cdph_Environment 'DEV' `
                -Cdph_ResourceInstance 1
            $keyVaultName | Should -Be 'kv-ITSD-123-123456-DEV01'
        }

        It 'Should return a valid Key Vault resource name with short names' {
            $keyVaultName = New-KeyVaultResourceName `
                -Cdph_Organization 'ITSD' `
                -Cdph_BusinessUnit '12' `
                -Cdph_BusinessUnitProgram '123' `
                -Cdph_Environment 'Dev' `
                -Cdph_ResourceInstance 1
            $keyVaultName | Should -Be 'kv-ITSD-12-123-DEV-01'
        }

        It 'Should drop the final hyphen without truncating the program name' {
            $keyVaultName = New-KeyVaultResourceName `
                -Cdph_Organization 'ITSD' `
                -Cdph_BusinessUnit '123' `
                -Cdph_BusinessUnitProgram '123456' `
                -Cdph_Environment 'DEV' `
                -Cdph_ResourceInstance 1
            $keyVaultName | Should -Be 'kv-ITSD-123-123456-DEV01'
        }
    }

    Context 'When the input is bad: Organization' {
        It 'Should require a valid organization' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }
    }

    Context 'When the input is bad: Business Unit' {
        It 'Should require a business unit' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }

        It 'Should require a minimum length of 2' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '1' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }

        It 'Should require a maximum length of 5' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123456' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }
    }

    Context 'When the input is bad: Business Unit Program' {
        It 'Should require a business unit program' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }

        It 'Should require a minimum length of 2' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }

        It 'Should require a maximum length of 7' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '12345678' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }
    }

    Context 'When the input is bad: Environment' {
        It 'Should require an environment' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_ResourceInstance 1 
            } | Should -Throw 
        }
    }

    Context 'When the input is bad: Resource Instance' {
        It 'Should require a resource instance' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' 
            } | Should -Throw 
        }

        It 'Should require a minimum value of 1' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 0 
            } | Should -Throw 
        }

        It 'Should require a maximum value of 99' {
            { 
                New-KeyVaultResourceName `
                    -Cdph_Organization 'ITSD' `
                    -Cdph_BusinessUnit '123' `
                    -Cdph_BusinessUnitProgram '1234567' `
                    -Cdph_Environment 'DEV' `
                    -Cdph_ResourceInstance 100 
            } | Should -Throw 
        }
    }
}