#Needs PSv5
#Run : Set-ServiceInfoFix -ComputerName [string] after . sourcing file.
#      Will return [ServiceName] fixed if no problems, 
#      -or [ServiceName] error if cannot fix.
#Written : 10/21/2016
#Author : JW @FPieces
#Additional info from : http://www.ryanandjeffshow.com/blog/2013/04/11/powershell-fixing-unquoted-service-paths-complete/
####

class ServiceFixInfo {
    [string] $ServiceName
    [string] $ServicePath
    [string] $FixedPath

    ServiceFixInfo ($ServiceName, $ServicePath, $FixedPath) {
        $this.ServiceName = $ServiceName
        $this.ServicePath = $ServicePath
        $this.FixedPath = $FixedPath
    }
}

function Get-ServiceFixInfo ($ComputerName) {
    Get-WmiObject -Class win32_service -ComputerName $ComputerName | ForEach-Object {
        if (($_.PathName -match " ") -and ($_.PathName -notmatch '"')) {
            $Service = $_
            $PathName = $Service.PathName

            $PathNoSwitch = ""
            $PathSplit = ""
            if ($PathName -match "/") {
                try {
                    $PathNoSwitch = $PathName -replace $PathName.Substring($PathName.IndexOf("/"), ($PathName.Length - $PathName.IndexOf("/")))
                    $PathSplit = $PathName.Substring($PathName.IndexOf("/"), ($PathName.Length - $PathName.IndexOf("/")))
                }
                catch {
                    #Lazy error handling...
                }
            }

            elseif ($PathName -match "-") {
                try {
                    $PathNoSwitch = $PathName -replace $PathName.Substring($PathName.IndexOf("-"), ($PathName.Length - $PathName.IndexOf("-")))
                    $PathSplit = $PathName.Substring($PathName.IndexOf("-"), ($PathName.Length - $PathName.IndexOf("-")))
                }
                catch {
                    #Lazy error handling...
                }
            }
            else {
                $PathNoSwitch = $PathName
            }

            if ($PathNoSwitch.Trim() -match " ") {
                $ServiceFixInfo = [ServiceFixInfo]::new($Service.Name, $PathName, '"' + $PathNoSwitch.Trim() + '" ' + $PathSplit)
                Write-Output $ServiceFixInfo
            }
        }
    }
}

function Set-ServiceInfoFix ($ComputerName) {
    foreach ($sfi in (Get-ServiceFixInfo $ComputerName)) {
        $hklm = 2147483650
        $key = "System\CurrentControlSet\Services\" + $sfi.ServiceName
        $ValueName = "ImagePath"
        
        $wmi = Get-WmiObject -List "StdRegProv" -Namespace root\default -ComputerName $ComputerName
        
        $wmi.SetSTringValue($hklm, $key, $ValueName, $sfi.FixedPath) | Out-Null
        if (($wmi.GetStringValue($hklm, $key, $ValueName)).sValue -eq $sfi.FixedPath) {
            Write-Host $sfi.ServiceName fixed
        }
        else {
            Write-Host $sfi.ServiceName error
        }
    }
}