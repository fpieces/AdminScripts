#System Summary from Nessus API
#Written by @Fpieces
#01/11/2017

function Get-NessusScanSummary {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true,position=0)]
        [string]
        $Server,

        [parameter(mandatory=$false,position=1)]
        [int]
        $Port,

        [parameter(mandatory=$true,position=2)]
        [pscredential]
        $Credential 
    )

    process {
        #Could not get session to accept valid credentials without using PSCredential.  Setup session similar to : https://github.com/tenable/Posh-Nessus
        if (!($Port)) {
            if ($Server -ne "cloud.tenable.com") {
                throw "Port number not specified"
            }
            else {
                $Session = Invoke-RestMethod -Uri "https://$($Server)/session" -Method Post -Body (@{'username'= $Credential.UserName;'password'= $Credential.GetNetworkCredential().Password} | ConvertTo-Json) -ContentType "application/json"
            }
        }
        else {
            $Session = Invoke-RestMethod -Uri "https://$($Server):$($Port)/session" -Method Post -Body (@{'username'= $Credential.UserName;'password'= $Credential.GetNetworkCredential().Password} | ConvertTo-Json) -ContentType "application/json"
        }
        
        #Grab a list of all scans
        if (!($Port)) {
            $Scans = Invoke-RestMethod -Uri "https://$($Server)/scans" -Method Get -Headers @{'X-Cookie' = "token=$($Session.Token)"}
        }
        else {
            $Scans = Invoke-RestMethod -Uri "https://$($Server):$($Port)/scans" -Method Get -Headers @{'X-Cookie' = "token=$($Session.Token)"}
        }

        #loop through the scans and give summary of output.  In this case, only reviewing Med, High, Critical vulns, but can add low / info counts in the same way.
        foreach ($Scan in $Scans.scans) {
            if (!($Port)) {
                $ScanDetails = Invoke-RestMethod -Uri "https://$($Server)/scans/$($Scan.id)" -Method Get -Headers @{'X-Cookie' = "token=$($Session.Token)"}
            }
            else {
                $ScanDetails = Invoke-RestMethod -Uri "https://$($Server):$($Port)/scans/$($Scan.id)" -Method Get -Headers @{'X-Cookie' = "token=$($Session.Token)"}
            }

            $CriticalVulnCount = 0
            $HighVulnCount = 0
            $MediumVulnCount = 0

            foreach ($HostDetail in $ScanDetails.Hosts) {
                $CriticalVulnCount += $HostDetail.critical
                $HighVulnCount += $HostDetail.high
                $MediumVulnCount += $HostDetail.medium
            }
    
            Write-Output (New-Object PSObject -Property @{ Scan = $Scan.name; Critical = $CriticalVulnCount; High = $HighVulnCount; Medium = $MediumVulnCount } | Select Scan, Critical, High, Medium)
        }
    }
}
