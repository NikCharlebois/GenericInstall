function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProgramName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallFilePath,

        [Parameter()]
        [System.String]
        $Arguments,

        [Parameter()]
        [ValidateSet('Absent', 'Present')]
        [System.String]
        $Ensure = 'Present'
    )

    $UserPrograms = Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue
    $MachinePrograms = Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'  -ErrorAction SilentlyContinue
    if ($null -ne $MachinePrograms)
    {
        $MachinePrograms = $MachinePrograms | Where-Object {$null -ne $_.GetValue("DisplayName")}
    }

    if ($null -ne $UserPrograms -and $null -ne $MachinePrograms)
    {
        $AllPrograms = $UserPrograms + $MachinePrograms
    }
    elseif($null -eq $UserPrograms)
    {
        $AllPrograms = $MachinePrograms
    }
    elseif($null -eq $MachinePrograms)
    {
        $AllPrograms = $UserPrograms
    }
    foreach ($program in $AllPrograms)
    {
        $currentProgramName = $program.GetValue("DisplayName")

        # Software is already installed;
        if ($currentProgramName -eq $ProgramName)
        {
            Write-Verbose "$ProgramName is already installed on the machine."
            return @{
                InstallFilePath = $InstallFilePath
                ProgramName     = $ProgramName
                Arguments       = $Arguments
                Ensure          = 'Present'
            }
        }
    }

    Write-Verbose "$ProgramName was not found on the machine."
    return @{
            InstallFilePath = $InstallFilePath
            ProgramName     = $ProgramName
            Arguments       = $Arguments
            Ensure          = 'Absent'
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProgramName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallFilePath,

        [Parameter()]
        [System.String]
        $Arguments,

        [Parameter()]
        [ValidateSet('Absent', 'Present')]
        [System.String]
        $Ensure = 'Present'
    )

    $current = Get-TargetResource @PSBoundParameters
    if ($Ensure -eq 'Present' -and $current.Ensure -eq 'Absent')
    {
        Write-Verbose "Installing $ProgramName running: Start-Process -FilePath $InstallFilePath -ArgumentList $Arguments -Wait -PassThru"
        Start-Process -FilePath $InstallFilePath -ArgumentList $Arguments -Wait -PassThru | Out-Null
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProgramName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallFilePath,

        [Parameter()]
        [System.String]
        $Arguments,

        [Parameter()]
        [ValidateSet('Absent', 'Present')]
        [System.String]
        $Ensure = 'Present'
    )

    $current = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Test-TargetResource: [Current]$($current.Ensure)  vs  [Desired]$Ensure"
    if ($current.Ensure -eq $Ensure)
    {
        return $true
    }
    return $false
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $RuleMap
    )

    $InformationPreference = 'Continue'
    $UserPrograms = Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $MachinePrograms = Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object {$_.GetValue("DisplayName") -ne $null}
    $AllPrograms = $UserPrograms + $MachinePrograms
    $sb = [System.Text.StringBuilder]::new()
    $i = 1
    foreach ($program in $AllPrograms)
    {
        $programName = $program.GetValue("DisplayName")
        Write-Information "    [$i/$($AllPrograms.Length)] $programName"
        
        $params = @{
            ProgramName     = $programName
            InstallFilePath = "\\"
        }

        $customEntry = $RuleMap.Programs | Where-Object {$_.Name -eq $programName}

        if ($null -ne $customEntry)
        {
            Write-Information "        * Found custom Rule Map entry for program $programName"
            $params.InstallFilePath = Join-Path -Path $RuleMap.Settings.BinaryFolder -ChildPath $customEntry.InstallerFile
            $params.Add("Arguments", $customEntry.Arguments)
            $results = Get-TargetResource @params
            [void]$sb.AppendLine('        GenericInstallBinaries ' + (New-Guid).ToString())
            [void]$sb.AppendLine('        {')
            $dscBlock = Get-DSCBlock -Params $results -ModulePath $PSScriptRoot
            [void]$sb.Append($dscBlock)
            [void]$sb.AppendLine("            PSDSCRunAsCredential = `$LocalAdminAccount")
            [void]$sb.AppendLine('        }')

            # Add Follow-up script if any
            if ($null -ne $customEntry.FollowUpScript)
            {
                [void]$sb.AppendLine('        Script ' + (New-Guid).ToString())
                [void]$sb.AppendLine('        {')
                [void]$sb.AppendLine('             GetScript = {' + $customEntry.FollowUpScript.Get + '}')
                [void]$sb.AppendLine('             SetScript = {' + $customEntry.FollowUpScript.Set + '}')
                [void]$sb.AppendLine('             TestScript = {$state = [scriptblock]::Create($GetScript).Invoke(); if($state["Ensure"] -eq "Present"){return $true}return $false;}')
                [void]$sb.AppendLine('        }')
            }
        }
        $i++
    }

    return $sb.ToString()
}
