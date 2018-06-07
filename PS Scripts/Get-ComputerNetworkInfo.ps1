class ComputerNetworkInfo {
    [string] $Manufacturer
    [string] $MacAddress
    [string] $IPAddress
    [string] $IPType
    [string] $ComputerName

    ComputerNetworkInfo ($Manufacturer, $MacAddress, $IPAddress, $IPType, $ComputerName) {
        $this.Manufacturer = $Manufacturer
        $this.MacAddress = $MacAddress
        $this.IPAddress = $IPAddress
        $this.IPType = $IPType
        $this.ComputerName = $ComputerName
    }
}

function Get-ComputerNetworkInfo {
    [cmdletbinding()]
    param(
        [string]
        $ComputerName,

        [switch]
        $IncludeIPv6,

        [pscredential]
        $Credential

    )
    
    process {
        
        if (!$ComputerName) {
            $ComputerName = $env:COMPUTERNAME
        }

        if ($Credential) {
            $NetworkAdapters = Get-WmiObject win32_NetworkAdapter -ComputerName $ComputerName -Credential $Credential | ? { ($_.MacAddress) }
        }
        else {
            $NetworkAdapters = Get-WmiObject win32_NetworkAdapter -ComputerName $ComputerName | Where-Object { ($_.MacAddress) }
        }

        foreach ($na in $NetworkAdapters | Select-Object *) {
            $MacAddress = $na.MACAddress

            if ($Credential) {
                $NetworkAdapterConfiguration = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "MacAddress = '$MacAddress'" -ComputerName $ComputerName -Credential $Credential
            }
            else {
                $NetworkAdapterConfiguration = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "MacAddress = '$MacAddress'" -ComputerName $ComputerName
            }

            $NetworkAdapterConfiguration | Select-Object -ExpandProperty IPAddress | ForEach-Object {
                $IPAddress = $_
                if (([ipaddress]::Parse($IPAddress)).AddressFamily -eq "InterNetwork") {
                    Write-Output ([ComputerNetworkInfo]::new($na.Manufacturer,
                                                             $na.MacAddress,
                                                             $IPAddress, 
                                                             "IPv4", 
                                                             $ComputerName)) 
                }
                else {
                    if ($IncludeIPv6) {
                        Write-Output ([ComputerNetworkInfo]::new($na.Manufacturer,
                                                                 $na.MacAddress,
                                                                 $IPAddress, 
                                                                 "IPv6", 
                                                                 $ComputerName))
                    }
                }
            }
        }
    }
}
