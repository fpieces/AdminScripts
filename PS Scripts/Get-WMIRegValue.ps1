function Get-WMIRegValue {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$false, Position=1)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$true, Position=2)]
        [validateset("HKCR", "HKCU", "HKLM", "HKU", "HKCC")]
        [string] 
        $RegHive,

        [parameter(Mandatory=$true, Position=3)]
        [string]
        $RegKey,

        [parameter(Mandatory=$true, Position=4)]
        [string]
        $ValueName,

        [parameter(Mandatory=$true, Position=5)]
        [validateset("Binary", "Dword", "Expanded", "Multi", "String")]
        [string]
        $RegType,

        [parameter(Mandatory=$false, Position=6)]
        [pscredential]
        $Credential
    )

    process {
        if ($ComputerName) {
            if ($Credential) {
                $StdRegProv = Get-WmiObject -List StdRegProv -Namespace root\default -ComputerName $ComputerName -Credential $Credential
            }
            else {
                $StdRegProv = Get-WmiObject -List StdRegProv -Namespace root\default -ComputerName $ComputerName
            }
        }
        else {
            $StdRegProv = Get-WmiObject -List StdRegProv -Namespace root\default 
        }
        
        if ($RegHive -eq "HKCR") { $RegTree = 2147483648 }
        elseif ($RegHive -eq "HKCU") { $RegTree = 2147483649 }
        elseif ($RegHive -eq "HKLM") { $RegTree = 2147483650 }
        elseif ($RegHive -eq "HKU") { $RegTree = 2147483651 }
        elseif ($RegHive -eq "HKCC") { $RegTree = 2147483653 }
        else { throw "No root!11!" }

        if ($RegType -eq "Binary") { 
            $Results = $StdRegProv.GetBinaryValue($RegTree, $RegKey, $ValueName)
            if ($Results.ReturnValue -eq 0) { 
                Write-Output $Results.uValue
            } 
            else { throw "Error reading Binary Value, Error: " + $Results.ReturnValue } 
        }
        elseif ($RegType -eq "Dword") { 
            $Results = $StdRegProv.GetDWORDValue($RegTree, $RegKey, $ValueName)
            if ($Results.ReturnValue -eq 0) { 
                Write-Output $Results.uValue
            } 
            else { throw "Error reading DWord Value, Error: " + $Results.ReturnValue } 
        }
        elseif ($RegType -eq "Multi") { 
            $Results = $StdRegProv.GetMultiStringValue($RegTree, $RegKey, $ValueName)
            if ($Results.ReturnValue -eq 0) { 
                Write-Output $Results.sValue
            } 
            else { throw "Error reading Multi String Value, Error: " + $Results.ReturnValue } 
        }
        elseif ($RegType -eq "String") { 
            $Results = $StdRegProv.GetStringValue($RegTree, $RegKey, $ValueName)
            if ($Results.ReturnValue -eq 0) { 
                Write-Output $Results.sValue 
            }
            else { throw "Error reading String Value, Error: " + $Results.ReturnValue } 
        }
        elseif ($RegType -eq "Expanded") {
            $Results = $StdRegProv.GetExpandedStringValue($RegTree, $RegKey, $ValueName)
            if ($Results.ReturnValue -eq 0) { 
                Write-Output $Results.sValue 
            }
            else { throw "Error reading Multi String Value, Error: " + $Results.ReturnValue }
        }
        else { throw "Somthing bad is happening..." }
    }
}