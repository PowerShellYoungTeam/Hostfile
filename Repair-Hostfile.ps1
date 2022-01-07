
############################# SCRIPT ######################################

$infile = "C:\temp\HostfileFix\posh_inputs\HostfileHostnames.CSV"

$outfile = "C:\temp\HostfileFix\Posh_outputs\HostFileRepair_$(get-date -f yyyy-MM-dd-HH-mm)_LOG.csv"

$HostfileEntry = "127.0.0.01 Server.POSHYT.corp"

$DefaultHostFile = "C:\temp\HostfileFix\hosts"

$Domain = "POSHYT"

Import-Csv -Path $infile -Header Computer | foreach-object {

  $computer = $result = $hostname = $pathexist = $Version = $HostfileEntryCheck = $HostfileModCheck = $HostFileErrorcheck = $Hostfile =  $Null

  $HostFilePath = "c$\windows\system32\drivers\etc\hosts"

  $hostname = $_.computer

    try{

        $Computer =  (Get-ADComputer -Identity $hostname -server $Domain -ErrorAction Stop)

        $MachineOnline = (Test-NetConnection $Computer.DNSHostName -CommonTCPPort SMB).TcpTestSucceeded

        if($true -eq $MachineOnline){
  
            $pathexist = Test-Path -Path "\\$($Computer.DNSHostName)\c$\App\Version.txt"  -ErrorAction Stop -PathType Leaf

            if($true -eq $pathexist){

                $Version = Get-Content "\\$($Computer.DNSHostName)\c$\App\Version.txt"

            }else{

                $Version = "N/A"

            }

            $HostFilePath = "\\$($Computer.DNSHostName)\$($HostFilePath)"


            $HostfileModCheck =  compare-object (get-content $HostFilePath) (get-content $DefaultHostFile)

            if ($null -eq $HostfileModCheck){

                $HostfileModCheck = "Host file hasn't been modified"

            }else{

                $HostfileModCheck = $HostfileModCheck.inputObject

            } 

            $Hostfile = Select-String $HostFilePath -Pattern $HostfileEntry

            if ($null -ne $Hostfile){

                $HostfileEntryCheck = $True

                $Hostfile.Line = ($Hostfile.Line).Trim()

                if($Hostfile.Line -eq $HostfileEntry){

                   $HostFileErrorcheck = $true

                   $HostfilePath = $Hostfile.Path


                }else{

                    $HostFileErrorcheck = $False

                    $HostfilePath = $Hostfile.Path 

                    Try{
                   
                        Get-ChildItem -Path $HostfilePath -ErrorAction Stop | Copy-Item -Destination { "$HostfilePath.old.$(Get-date -Format yyyyMMdd )" } -ErrorAction Stop

                        Get-ChildItem -Path $HostfilePath | write-host

                        Write-host -ForegroundColor Green "Host File Backup Complete on $($Computer.Name)"

                    }catch{
        
                        $ErrorMessage = $_.Exception.Message

                        Write-host -ForegroundColor RED "Issue backing up the host File on $($Computer.Name) because $($ErrorMessage)"

                    }

                    Try{

                        get-content $HostfilePath | write-host

                        (get-content $HostfilePath -ErrorAction Stop) | foreach-object {$_ -replace $HostfileEntry,""} -ErrorAction Stop | set-content $HostfilePath -ErrorAction Stop

                        Write-host -ForegroundColor Green "Host File Backup Complete on $($Computer.Name)"

                        Add-Content -Path $HostfilePath -value $HostfileEntry -ErrorAction Stop

                        get-content $HostfilePath | write-host

                        $HostFileErrorcheck = "Repaired"

                    }catch{
        
                        $ErrorMessage = $_.Exception.Message

                        Write-host -ForegroundColor RED "Issue Repairing Host File on  $($Computer.Name) because $($ErrorMessage)"

                        $HostfileEntryCheck = "Repaired Failed due to $($ErrorMessage)"

                    }


                    }

                        

            }else{

                $HostfileEntryCheck = $False

            }

        }Else{
            
            $Version = "offline"
            $pathexist = "offline"
            $HostfileModCheck = "offline"
            $HostfileEntryCheck = "offline"

        }
    
            [PSCustomObject][ordered]@{
                Computer = $hostname
                'App Install' = $pathexist
                'App Version' = $Version
                'Host File modified' = [string]$HostfileModCheck 
                'Host File Entry' = $HostfileEntryCheck 
                'Host file Entry successfull' = $HostFileErrorcheck
                'Host File Path' = $HostfilePath
            } | Export-Csv -Path $outfile -NoTypeInformation -Append

        }catch{

            $errormsg = $_.Exception.Message

            [PSCustomObject][ordered]@{
                Computer = $hostname
                'App Install' = $errormsg
                'App Version' = $Version
                'Host File modified' = [string]$HostfileModCheck
                'Host File Entry' = $HostfileEntryCheck
                'Host file Entry successfull' = $HostFileErrorcheck
                'Host File Path' = $HostfilePath 
            } | Export-Csv -Path $outfile -NoTypeInformation -Append
    }
} 



################ End of Script #########################################
