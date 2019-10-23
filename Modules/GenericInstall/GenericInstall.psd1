@{
    # Version number of this module.
    moduleVersion = '1.0.0.0'
    
    # ID used to uniquely identify this module
    GUID = '7a6185bd-af2b-4da0-8b12-e586c4cba53c'
    
    # Author of this module
    Author = 'Microsoft Corporation'
    
    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'
    
    # Copyright statement for this module
    Copyright = '(c) 2019 Microsoft Corporation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module with DSC Resources for Generic Software Installation'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'
    
    # Adds dependency to ReverseDSC
    RequiredModules = @(@{ModuleName = "ReverseDSC"; RequiredVersion = "1.9.4.7"; })
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
    
        PSData = @{
    
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')
    
            # A URL to the license for this module.
            LicenseUri = ''
    
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/NikCharlebois/GenericInstall'
    
            # A URL to an icon representing this module.
            # IconUri = ''
    
            # ReleaseNotes of this module
            ReleaseNotes = ''
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @('Modules\ReverseDSCCollector.psm1')
    
    # Functions to export from this module
    FunctionsToExport = '*'
    
    # Cmdlets to export from this module
    CmdletsToExport = 'Export-GenericInstallConfiguraton'
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    