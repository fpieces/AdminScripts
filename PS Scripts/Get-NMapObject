function Get-NMapObject {
<#
    .Example
    Get-NMap -nmapEXEPath "C:\nmap\nmap-7.70\nmap.exe" -nmapParameters "-T4 -F -n -sV 192.168.0.0/24" | ft HostName, Port, Type, Status, ServiceName, Version
#>
    [cmdletbinding()]
    param(
        [string]
        $nmapEXEPath,

        [string]
        $nmapParameters
    )
    process {
        #Nmap Execution
        $nmapCmd = "$nmapEXEPath $nmapParameters"
        $nmapResults = Invoke-Expression $nmapCmd

        #Formatting
        $Services = @()
        foreach ($ResultLine in $nmapResults) {
   
            if ($ResultLine -match "nmap scan report for") {
                $HostName = ($ResultLine -replace "Nmap scan report for", "").Trim()
            }

            if ($ResultLine -match "/" -and $ResultLine -notmatch "Starting Nmap") {
                $Services = $Services + $ResultLine
            }

            if ($ResultLine -match "MAC") {

                foreach ($Service in $Services) {
                    if (-not($Service -match "Service Info:")) {
                
                        $Port = $Service.Substring(0, $Service.IndexOf("/"))
                        $Type = ($Service -replace $Port, "" -replace "/")
                        $Status = ($Service -replace $Port, "" -replace $Type.Substring(0, $Type.IndexOf(" ")), "" -replace "/", "").Trim()
                        $ServiceType = ($Service -replace $Port, "" -replace $Type.Substring(0, $Type.IndexOf(" ")), "" -replace $Status.Substring(0, $Status.IndexOf(" ")), "" -replace "/", "").Trim()

                        if ($ServiceType.IndexOf(" ") -eq -1) {
                            $ServiceName = $ServiceType
                            $Version = ""
                        }
                        else {
                            $ServiceName = $ServiceType.Substring(0, $ServiceType.IndexOf(" ")).Trim()
                            $Version = ($ServiceType -replace $ServiceName, "").Trim()
                        }

                        $ResultsObject = New-Object PSObject -Property @{ HostName = $HostName
                                                                          Port = $Port
                                                                          Type = $Type.Substring(0, $Type.IndexOf(" "))
                                                                          Status = $Status.Substring(0, $Status.IndexOf(" "))
                                                                          ServiceName = $ServiceName
                                                                          Version = $Version
                                                                          }

                        Write-Output $ResultsObject
                    }
                }
                $Services = @()
            }
        }   
    }
}

