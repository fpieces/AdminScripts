cls
#Test to see what/where a logged on user account will have admin privileges on a domain.
#Written by @Fpieces
#12/16/2016

$Searcher = (New-Object System.DirectoryServices.DirectorySearcher -ArgumentList (New-Object System.DirectoryServices.DirectoryEntry -ArgumentList "LDAP://$env:USERDOMAIN"))
$Searcher.PageSize = 10000
$Results = $Searcher.FindAll()

$UserAccount = ($Results | ? { $_.Properties["sAMAccountName"] -eq "$env:USERNAME" })
$UserGroups = $UserAccount.Properties["MemberOf"].ForEach({ $env:USERDOMAIN + "\" + $_.Replace("CN=", "").Substring(0, $_.Replace("CN=","").IndexOf(",")) })

$ComputerList = ($Results | ? { $_.Properties["ObjectClass"] -match "Computer" }).ForEach({ ($_.Properties["Name"])[0] + "." + $env:USERDOMAIN })
foreach ($Computer in $ComputerList) {
    $IsAdmin = $false
    try {
        if (Test-Connection -ComputerName $Computer -Count 1 -BufferSize 1 -Quiet) {
            $AdminMembers = @($([ADSI]"WinNT://$Computer/Administrators,group").psbase.Invoke('Members'))
        
            foreach ($Member in $AdminMembers) {
                $MemberName = $Member.GetType.Invoke().InvokeMember('Adspath', 'GetProperty', $Null, $Member, $Null).Replace("WinNT://", "").Split("/")[1]
                if ($Member.GetType.Invoke().InvokeMember('Class', 'GetProperty', $Null, $Member, $Null) -eq "Group") {
                    if ($UserGroups -contains $MemberName) {
                        $IsAdmin = $true
                    }
                }
                else {
                    if ($MemberName -eq $env:USERNAME) {
                        $IsAdmin = $true
                    }
                }
            }

            $ComputerShares = net.exe view $Computer /all
            for ($i = 7; $i -le ($ComputerShares.Count -3); $i++) {
                $ComputerShare = "\\$Computer\" + $ComputerShares[$i].Substring(0, $ComputerShares[$i].IndexOf(" "))
                if ($IsAdmin) {
                    Write-Output "$ComputerShare : pwned by local admin membership"
                }
                else {
                    if (Test-Path $ComputerShare -ErrorAction SilentlyContinue) {
                        $ModifyOrHigher = (Get-Acl $ComputerShare -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Access | Where-Object { (($_.FileSystemRights -imatch "FullControl") -or ($_.FileSystemRights -imatch "Modify")) }).IdentityReference
                        foreach ($ShareMember in $ModifyOrHigher) {
                            if ($ShareMember -match "Users") {
                                Write-Output "$ComputerShare : pwned by users group having modify or full control"
                            }
                            elseif ($ShareMember -match "Everyone") {
                                Write-Output "$ComputerShare : pwned by everyone group having modify or full control"
                            }
                            else {
                                if ($UserGroups -contains $ShareMember.Value.Trim()) {
                                    Write-Output "$ComputerShare : pwned by $ShareMember domain group having modify or full control"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        #Do nothing with errors because Access Denied, etc... are expected to be thrown.
    }
}
