function Export-GenericInstallConfiguration
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()]
        [System.String]
        $RuleMapPath
    )

    $RuleMap = Import-PowerShellDataFile -Path $RuleMapPath

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("Configuration GenericInstallations")
    [void]$sb.AppendLine("{")
    [void]$sb.AppendLine("    Import-DSCResource -ModuleName GenericInstall")
    [void]$sb.AppendLine("    Node localhost")
    [void]$sb.AppendLine("    {")

    $ResourcesPath = Join-Path -Path $PSScriptRoot `
                               -ChildPath "..\DSCResources\" `
                               -Resolve
    $AllResources = Get-ChildItem $ResourcesPath -Recurse | Where-Object {$_.Name -like 'MSFT_*.psm1'}

    foreach ($ResourceModule in $AllResources)
    {
        Import-Module $ResourceModule.FullName | Out-Null
        $exportString = Export-TargetResource -RuleMap $RuleMap
        [void]$sb.Append($exportString)
    }

    [void]$sb.AppendLine("    }")
    [void]$sb.AppendLine("}")
    [voic]$sb.AppendLine("GenericInstallations")

    #region Prompt the user for a location to save the extract and generate the files
    if ($null -eq $Path -or "" -eq $Path)
    {
        $OutputDSCPath = Read-Host "Destination Path"
    }
    else
    {
        $OutputDSCPath = $Path
    }

    while ((Test-Path -Path $OutputDSCPath -PathType Container -ErrorAction SilentlyContinue) -eq $false)
    {
        try
        {
            Write-Information "Directory `"$OutputDSCPath`" doesn't exist; creating..."
            New-Item -Path $OutputDSCPath -ItemType Directory | Out-Null
            if ($?) {break}
        }
        catch
        {
            Write-Warning "$($_.Exception.Message)"
            Write-Warning "Could not create folder $OutputDSCPath!"
        }
        $OutputDSCPath = Read-Host "Please Provide Output Folder for DSC Configuration (Will be Created as Necessary)"
    }
    <## Ensures the path we specify ends with a Slash, in order to make sure the resulting file path is properly structured. #>
    if (!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
    {
        $OutputDSCPath += "\"
    }
    $outputDSCFile = $OutputDSCPath + "GenericInstallations.ps1"
    $sb.ToString() | Out-File $outputDSCFile

    Invoke-Item -Path $OutputDSCPath
    #endregion
}
