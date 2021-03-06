############################################################################################################################################################################
# vSphere Functions
############################################################################################################################################################################
# Function Name : login
# Description : Login to the ESXi server
# Uses xml input parameters : ipaddress ,username and password
# Created by : Amit
function connect_host($host_d){
    Write-Host -ForegroundColor:Cyan "Connecting to ESXi Host -------"
	$conn_esxi = Connect-VIServer -Server $host_d.ipaddress -User $host_d.username -Password $host_d.password -Port '443' -ErrorAction:SilentlyContinue -ErrorVariable errormsg 
	if ($errormsg){
      Write-Host -ForegroundColor:White "Unable to connect to the esxi server, Exiting................."
	  Write-Host -ForegroundColor:Red "Error message : $errormsg"
      exit(0)
   }
	
}

# Function Name : createvswitch
# Description : Create a vSwitch in ESXi server
# Uses xml input parameters : vswitch_name and ipaddress
# Created by : Amit
function createvswitch($xml1,$xml2){
    Write-Host -ForegroundColor:White "`nCreating the vSwitch -------"
	Write-Host -ForegroundColor:Green $xml1
	$createvswitch = New-VirtualSwitch -Name $xml1 -VMHost $xml2 -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg | Out-Null
	if ($errormsg){
      Write-Host -ForegroundColor:White "Unable to create vSwitch................."
	  Write-Host -ForegroundColor:Red "Error message : $errormsg"
      exit(0)
	  }
}

# Function Name : createvpg
# Description : Create a vPortgroup in vSwitch
# Uses xml input parameters : vpg_name ,vlanid and vswitch_name
# Created by : Amit
function createvpg($xml1, $xml2, $xml3){
    Write-Host -ForegroundColor:White "`nCreating the vPortgroup............."
	Write-Host -ForegroundColor:Yellow $xml1
	$createvswitch = New-VirtualPortGroup -Name $xml1 -VLanId $xml2 -VirtualSwitch $xml3 -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
	if ($errormsg){
      Write-Host -ForegroundColor:White "Unable to create virtual portgroup................."
	  Write-Host -ForegroundColor:Red "Error message : $errormsg"
      exit(0)
	  }
}

# Function Name : createvpg
# Description : Create a vPortgroup in vSwitch
# Uses xml input parameters : vpg_name
# Created by : Amit
function setPromiscuous($xml1){
	Write-Host -ForegroundColor:White "Setting Security Policy of the vPortgroup............." $xml1
    Get-VirtualPortgroup -Name $xml1 | Get-SecurityPolicy | Set-SecurityPolicy -AllowPromiscuous $true
	}
	
	
## Function Name : createroutervm
## Description : Create the virtual routers
## Uses xml input parameters : vmname, esxi_ip, datastore, network, isopath
## Created by : Amit
function createroutervm($xml1, $xml2, $xml3, $xml4, $xml5){

    Write-Host -ForegroundColor:White "`nCreating Virtual Router ------ "
	Write-Host -ForegroundColor:Blue $xml1
	$createvmresult = New-VM -Name $xml1 -VMHost $xml2 -Datastore $xml3 -NetworkName $xml4 -MemoryMB 512 -DiskMB 10240 -DiskStorageFormat Thin -NumCPU 1 -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
	$cd = New-CDDrive -VM $xml1 -ISOPath $xml5 -StartConnected
    Start-VM -VM $xml1 	
}

## Function Name : createclientvm
## Description : Create the client machines at LAN and Server side
## Uses xml input parameters : vmname, esxi_ip, datastore, network, isopath
## Created by : Amit
function createclientvm($xml1, $xml2, $xml3, $xml4, $xml5){

    Write-Host -ForegroundColor:DarkYellow "`nCreating Client Machine ------ "
	Write-Host -ForegroundColor:Blue $xml1
	$createvmresult = New-VM -Name $xml1 -VMHost $xml2 -Datastore $xml3 -NetworkName $xml4 -MemoryMB 1024 -DiskMB 20480 -DiskStorageFormat Thin -NumCPU 2 -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
	$cd = New-CDDrive -VM $xml1 -ISOPath $xml5 -StartConnected
    Start-VM -VM $xml1 	
}

## Function Name : configrouter
## Description : Send the config.boot file to router and restart the vyatta-router service
## Uses xml input parameters : vmname, esxi_ip, config_file
## Created by : Amit
function configrouter($host_d, $vmname, $location){

    Write-Host -ForegroundColor:DarkYellow "`nConfiguring routers ------ "
	Write-Host -ForegroundColor:Blue $vmname
	Invoke-VMScript -VM $vmname -HostUser $host_d.username -HostPassword $host_d.password -GuestUser vyos -GuestPassword vyos -ScriptText "cp /config/config.boot /config/config_backup.boot" -LocalToGuest
    Copy-VMGuestFile -VM $vmname -HostUser $host_d.username -HostPassword $host_d.password -GuestUser vyos -GuestPassword vyos -Source $location -Destination "/config/" -LocalToGuest
	Sleep -Seconds 30
	Invoke-VMScript -VM $vmname -HostUser $host_d.username -HostPassword $host_d.password -GuestUser vyos -GuestPassword vyos -ScriptText "/etc/init.d/vyatta-router restart"
  	
}

# Function Name : disconnect_host
# Description : Logout of the Host/vCenter
# Uses xml input parameters : none
# Created by : Amit
function disconnect_host(){
	$conn_esxi = Disconnect-VIServer -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg 
	if ($errormsg){
      Write-Host -ForegroundColor:White "Unable to connect to the esxi server, Exiting................."
	  Write-Host -ForegroundColor:Red "Error message : $errormsg"
      exit(0)
   }
   else{
   Write-Host -ForegroundColor:Cyan "`nDisconnected from esxi server"
   }
	
}

## Function Name : createresourcepool
## Description : Create new resourcepool under a ESX host
## Uses xml input parameters : ESX host pip
## Created by : Amit
#function createresourcepool($xml1){
#    $testcaseresults = "" |  select "TestcaseID","Description","Username","Results","Error"
#	$testcaseresults.description = "Create a new resourcepool"
#	$testcaseresults.username = $xml1.config.global.username
#	$rpname = "testrp" + "-" + (Get-Random -Minimum 500 -Maximum 999)
#	$createrpresult = New-ResourcePool -Name $rpname -Location (Get-VMHost $xml1.config.esxi1.pip) -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
#	$testcaseresults.error = $errormsg
#	return $testcaseresults
#}
### Function Name : deletevpg
### Description : Delete Virtual Port Group 
#### Uses xml input parameters : Username
### Created by : Amit
##function deletevpg($xml1){
##    $testcaseresults = "" |  select "TestcaseID","Description","Username","Results","Error"
##	$testcaseresults.description = "Delete Virtual Port Group"
##	$testcaseresults.username = $xml1.config.global.username
##	$deletevpg = Remove-VirtualPortGroup -VirtualPortGroup (Get-VirtualPortGroup -VMHost $xml.config.esxi1.oip -Name vpg76) -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
##	$testcaseresults.error = $errormsg
##	return $testcaseresults
##}
##
##
### Function Name : removevswitch
### Description : Remove Virtual Switch
#### Uses xml input parameters : VMName1
### Created by : Amit
##function removevswitch($xml1){
##    $testcaseresults = "" |  select "TestcaseID","Description","Username","Results","Error"
##	$testcaseresults.description = "Remove Virtual Switch"
##	$testcaseresults.username = $xml1.config.global.username
##	$deletevswitch = Remove-VirtualSwitch -VirtualSwitch (Get-VirtualSwitch -VMHost $xml1.config.esxi1.oip -Name vSwitch76) -Confirm:$false -ErrorAction:SilentlyContinue -ErrorVariable errormsg
##	$testcaseresults.error = $errormsg
##	return $testcaseresults
##}
##
##
### Function Name : deletevm
### Description : Delete VM from disk
### Uses xml input parameters : VMName1
### Created by : Amit
##function deletevmesxi($xml1){
##    $testcaseresults = "" |  select "TestcaseID","Description","Username","Results","Error"
##	$testcaseresults.description = "Delete Virtual Machine from the Disk"
##	$testcaseresults.username = $xml1.config.global.username
##	$vm = $xml1.config.esxi1.VMName2;
##	$deletevmresult = Remove-VM -VM $vm -confirm:$false -DeletePermanently -ErrorAction:SilentlyContinue -ErrorVariable errormsg
##	$testcaseresults.error = $errormsg
##	return $testcaseresults