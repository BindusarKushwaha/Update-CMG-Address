#######################################
#Please change the CMGName here with the correct one.
$NewCMG ="Binlabs.CLOUDAPP.NET/CCM_Proxy_MutualAuth/72057594123458092"
#AZAU2CMG.SOUTHEASTASIA.CLOUDAPP.AZURE.COM/CCM_Proxy_MutualAuth/1401
#Do you want to create New CMG regitry as well if its blank? Or just want to change the Old CMG with new One?
$NVForce=$False

#######################################


############# Please do not change anything below this line 

<# DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS #>

<#PSScriptInfo
 
.VERSION 1.0
 
.GUID
 
.AUTHOR Bindusar Kushwaha
 
.COMPANYNAME Microsoft
 
.COPYRIGHT
 
.TAGS
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
The purpose of this script is to create or update CMG address for client machines.
#>


#Function to create the Log File and update it.
Function Write-Host()
{
    <#
    .SYNOPSIS
    This function is used to configure the logging.
    .DESCRIPTION
    This function is used to configure the logging.
    .EXAMPLE
    Logging -Message "Starting installation" -severity 1 -component "Installation"
    Logging -Message "Something went wrong" -severity 2 -component "Installation"
    Logging -Message "BIG Error Message" -severity 3 -component "Installation"
    .NOTES
    NAME: Logging
    #>
    PARAM(
        [Parameter(Mandatory=$true)]$Message,
         #[String]$Path = "c:\Windows\Temp\Autopilot_Custom.log",
         [int]$severity=1,
         [string]$component="CMGChange"
         )

         $logdir="C:\Temp"        If(!(Test-Path $logdir))        {           $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue        }
                $StartTime = Get-Date -Format "dd-MM-yyyy"        [String]$Path = "$Logdir\CMGChange_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

##### Registry Changes #####
Function Add_Reg()
{
    Param(
        [Parameter(Mandatory=$True)]$Path,
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)]$Value,
        [Parameter(Mandatory=$True)]$PropertyType
    )
    $ErrorActionPreference="SilentlyContinue"

    Write-Host "----------------"
    Write-Host "Initiating the function to add registry under $path"
    Write-Host "Reg name $Name will have value $Value"

    #$Path='HKLM:\SOFTWARE\Microsoft\SMS\Client\Internet Facing'

    If(Test-Path $Path)
    {
        Write-Host "Found Reg Path already there..."
        If(((Get-ItemProperty -Path "$Path").$Name) -eq "$Value")
        {
            Write-Host "Regsitry name is also correct with appropriate value..."
            Write-Host "Going to Main Script..."
        }
        Else
        {
            Write-Host "Error in finding the appropriate value" -severity 2
            If(((Get-ItemProperty -Path "$Path").$Name))
            {
                Write-Host "Reg value of $Name is not matching with $Value... Updating it..."
                Try
                {
                    Set-ItemProperty -Path "$Path" -Name "$Name" -Value "$Value"
                }
                Catch
                {
                    Write-Host "Failed to create Key at $Path"
                    Write-Host "$Error[0]"
                    Exit 1
                }
            }
            Else
            {
                Write-Host "Reg does not exist... Creating one with name $Name and setting $Value"
                Try
                {
                    New-ItemProperty -Path "$Path" -Name "$Name" -PropertyType $PropertyType -Value "$Value" -ErrorAction Stop
                }
                Catch
                {
                    Write-Host "Failed to create Key at $Path"
                    Write-Host "$Error[0]"
                    Exit 1
                }
            }
        }
    }
    else
    {
        Write-Host "Failed to find the path $Path" -severity 2
        Write-Host "Creating the new Path $Path"
        Try
        {
            New-Item -Path "$Path" -Force -ErrorAction Stop
        }
        Catch
        {
            Write-Host "Failed to create Key at $Path"
            Write-Host "$Error[0]"
            Exit 1
        }

        Write-Host "Starting the Function..."
        Add_Reg -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType
    }
    Write-Host "----------------"
}

Function Update_Reg()
{
    Param(
    [Parameter(Mandatory=$True)]$Path,
    [Parameter(Mandatory=$True)]$Name,
    [Parameter(Mandatory=$True)]$Value,
    [Parameter(Mandatory=$True)]$PropertyType
    )

     $ErrorActionPreference="SilentlyContinue"

    Write-Host "----------------"
    Write-Host "Initiating the function to update registry under $path"
    Write-Host "Checking $Name have value $Value already..."

    If(Test-Path -Path $Path)
    {
        Write-Host "Found Reg Path already there..."
        If(((Get-ItemProperty -Path "$Path").$Name) -eq "$Value")
        {
            Write-Host "Regsitry name is also correct with appropriate value..."
            Write-Host "Going to Main Script..."
        }
        Else
        {
            Write-Host "Error in finding the appropriate value" -severity 2
            If(((Get-ItemProperty -Path "$Path").$Name))
            {
                Write-Host "Reg value of $Name is not matching with $Value... Updating it..."
                Try
                {
                    Set-ItemProperty -Path "$Path" -Name "$Name" -Value "$Value"
                }
                Catch
                {
                    Write-Host "Failed to create Key at $Path"
                    Write-Host "$Error[0]"
                    Exit 1
                }
            }
            Else
            {
                Write-Host "Reg does not exist..."
                #New-ItemProperty -Path "$Path" -Name "$Name" -PropertyType $PropertyType -Value "$Value"
            }
        }
    }
    else
    {
        Write-Host "there is no CMG Address added at $Path... will discard" -severity 2
        #Write-Host "Creating the new Path $Path"

        #New-Item -Path "$Path" | Out-Null

        #Write-Host "Starting the Function..."
        #Add_Reg -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType
    }
    Write-Host "----------------"
}


$Error.Clear()


Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"

Write-Host -Message "Checking if SCCM Agent is installed..."

If(Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\CCM')
{
    Write-Host -Message "Found SCCM Agent installed as per Registry..."
    Write-Host "Proceeding further for CMG Change..."

    If($NVForce -eq $True)
    {
        Write-Host "Forcing CMG address to be added/updated in registry"
        Add_Reg -Path "HKLM:\SOFTWARE\Microsoft\SMS\Client\Internet Facing" -Name "Internet MP hostname" -Value "$NewCMG" -PropertyType String
    }
    Else
    {
        Write-Host "CMG address to be updated in registry"
        Update_Reg -Path "HKLM:\SOFTWARE\Microsoft\SMS\Client\Internet Facing" -Name "Internet MP hostname" -Value "$NewCMG" -PropertyType String
    }
}

Else
{
    Write-Host -Message "CCM Key is missing. Seems like SCCM Agent is not even Installed. exiting the script."
    Write-Host -Message "Please install SCCM Agent first!!!"
}

Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"