
# Configure creadentials for use with the VMware vSphere Provider
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "vcenterpassword"
  vsphere_server = "vcenter.fqdn.com"


# Uncomment the below line if you have a self-signed vCenter cert
  allow_unverified_ssl = true
}

# Number of VMs to create
# Note that the IP address information need to match the number of VMs to create,
# even if DHCP is used
locals {
  vmCount = 3
}

module "jonamiki-windows-vm" {
  source        = "Terraform-VMWare-Modules/vm/vsphere"
  version       = "3.3.0"              # Specify the version of the vSphere provider to use
  dc            = "ASRock DC"          # Name of data center in vSphere to deploy to
  vmrp          = "Terraform"          # Resource Pool
  vmfolder      = "TF-Win"             # VM folder to place the newly created VMs in
  datastore     = "vsanDatastore"      # What vSphere storage to use for the VMs
  vmtemp        = "win2016-template"   # vSphere template to use as base for new VMs
  instances     = local.vmCount        # Here we reference the vmCount variable listed above
  vmname       = "windows-vm-"
  vmnameformat  = "%03d"               # %02 gives "VM-Name-01",  %03 gives "VM-Name-001", ...
  # In the network section, enter the vSwitch or vDS port group to use + IP addresses or "" for DHCP
  network = {
    # DHCP:
    "vDS-VL702" = ["","",""]
    # Fixed IP:
    # "vDS-VL702" = ["10.70.2.101","10.70.2.102","10.70.2.103"]
  }
  # If fixed IP is used, uncomment ipv4submask, vmgateway and dns_server_list below:
  # ipv4submask      = ["24"]
  # vmgateway        = "10.70.2.254"
  # dns_server_list  = ["192.168.0.10", "192.168.0.1"]
  network_type      = ["vmxnet3"]     # Can be vmxnet3, e1000, e1000e or sriov
  scsi_bus_sharing  = "noSharing"     # Can be set to physicalSharing, virtualSharing or noSharing
  scsi_type         = "lsilogic-sas"  # Can be set to lsilogic, lsilogi-sas or pvscsi
  scsi_controller   = 0               # This will assign OS disk to controller 0
  enable_disk_uuid  = false           # Optionally expose the UUID of the disk to the VM
  auto_logon        = true            # Enable to have the VM log on automatically after creation (no manual login required)
                                      # auto_logon is required if run_once commands are executed after VM deployment

  # Optionally run commands after VM creation. Use with "auto_logon" above.
  # In this example we enable and allow RDP connections from any source, disable the firewall (not generally recommended)
  # Finally a PowerShell script to install the AWS SSM agent is downloaded via HTTP from a local web host and executed
  run_once = [
    "cmd.exe /C Powershell.exe Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -name \"fDenyTSConnections\" -value 0",
    "cmd.exe /C Powershell.exe Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' -name \"UserAuthentication\" -value 0",
    "cmd.exe /C Powershell.exe NetSh Advfirewall set allprofiles state off",
  #   "cmd.exe /C Powershell.exe Invoke-WebRequest -Uri http://192.168.2.194:8000/installSsmAgent.ps1 -OutFile installSsmAgent.ps1",
  #   "cmd.exe /C Powershell.exe installSsmAgent.ps1"
  ]
  orgname          = "Terraform-Module" # Organization name (shows up in "About Windows" when running the command "winver")
  workgroup        = "Unicorn-Workgrp"  # Workgroup to add the VMs into after creation
  is_windows_image = true               # Required when creating Windows VMs. Can be skipped / removed for Linux
  firmware         = "efi"              # If the VMs only boot up to a black screen, change this to "bios"
  local_adminpass  = "windowspassword"  # Local Windows Administrator user password
}



# Output the names of the newly created VMs along with their IP addresses
output "vmnames" {
  value = module.jonamiki-windows-vm.VM
}

output "vmnameswip" {
  value = module.jonamiki-windows-vm.ip
}
