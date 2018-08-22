<#
.SYNOPSIS
  This script aims to generate sysmon policies from sysmon modules

.DESCRIPTION
  Read sysmon modules names
  Merge modules for creating policies

.PARAMETER ReferencePolicyPath
  Configuration skeleton

.PARAMETER OutFolder
  Destination folder for the generated Policies

.OUTPUTS
  Sysmon policies

.NOTES
  Version:        1.0
  Author:         SOUMILL
  Creation Date:  August 21th 2018
  Purpose/Change: Initial script development
  

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

param(
  [string]$ReferencePolicyPath,
  [string]$OutFolder = "../"
)

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$Script_Version = "1.0"

#
$All_Sysmon_Modules

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Create-Output-Folder
{
    try
    {
        if (-not (Test-Path $OutFolder))
        {
            New-Item -ItemType directory -Path $OutFolder
        }
    }
    catch
    {
        Write-Error $_.Exception
    }
}

function Get-Sysmon-Modules
{
    try
    {
        $All_Sysmon_Modules = Get-ChildItem -Path . -Filter *.xml* -Recurse -ErrorAction SilentlyContinue
        return $All_Sysmon_Modules
    }
    catch
    {
        Write-Error $_.Exception
    }
}

#Check file suffix for getting policy names
function Get-Policy-Names ($All_Sysmon_Modules)
{
    try
    {
        $Policy_Names = @("common")
        #Check all extensions 
        foreach ($Mod in $All_Sysmon_Modules)
        {
            $Mod_Array = $Mod.Name.Split('.')
            #Continue if the module is a global one
            if ($Mod_Array.Length -eq 2)
            {
                continue
            }
            #Get Policy Name
            for ($i = 2 ; $i -lt $Mod_Array.Length ; ++$i)
            {
                $Policy_Names += $Mod_Array[$i]
            }
        }
        #Remove duplicates
        $Policy_Names = $Policy_Names | Select -Unique
        return $Policy_Names
    }
    catch
    {
        Write-Error $_.Exception
    }
}

function Generate-Sysmon-Policies ($All_Sysmon_Modules, $Policy_Names)
{
    #try
    #{
        #Iterate through Policies
        foreach ($Policy in $Policy_Names)
        {
            $Policy_Modules = @()
            #Iterate through Sysmon modules
            foreach ($Mod in $All_Sysmon_Modules) 
            {
                $Mod_Array = $Mod.Name.Split('.')
                #if the module is global add it to the policy
                if ($Mod_Array.Length -eq 2)
                {
                    $Policy_Modules += $Mod
                }
                else
                {
                    #Check if the policy is linked to the module name
                    for ($i = 2 ; $i -lt $Mod_Array.Length ; ++$i)
                    {
                        if ($Mod_Array[$i] -eq $Policy)
                        {
                            $Policy_Modules += $Mod
                        }               
                    }
                }
            }
            #Generate Sysmon profile
            $Filename = "sysmon_" + $Policy + ".xml"
            $Policy_Modules | Merge-SysmonXMLConfiguration -ReferencePolicyPath $ReferencePolicyPath | Out-File (Join-Path -Path $OutFolder -ChildPath $Filename)
        }
    #}
    #catch
    #{
    #    Write-Error $_.Exception
    #}
    
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

$All_Sysmon_Modules = Get-Sysmon-Modules

$Policy_Names = Get-Policy-Names $All_Sysmon_Modules

Create-Output-Folder

Generate-Sysmon-Policies $All_Sysmon_Modules $Policy_Names
