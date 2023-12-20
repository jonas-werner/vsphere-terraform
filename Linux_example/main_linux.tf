
# Configure creadentials for use with the VMware vSphere Provider
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "vcenterpassword"
  vsphere_server = "vcenter.fqdn.com"


  # if you have a self-signed cert
  allow_unverified_ssl = true
}

locals {
  vmCount = 10
}

module "jonamiki-linux-vm" {
  source        = "Terraform-VMWare-Modules/vm/vsphere"
  version       = "3.3.0"              # Specify the version of the vSphere provider to use
  dc            = "ASRock DC"          # Name of data center in vSphere to deploy to
  vmrp          = "Terraform"          # Resource Pool
  vmfolder      = "Test-VMs"             # VM folder to place the newly created VMs in
  datastore     = "vsanDatastore"      # What vSphere storage to use for the VMs
  vmtemp        = "ubuntu-22.04-template"   # vSphere template to use as base for new VMs
  instances     = local.vmCount        # Here we reference the vmCount variable listed above
  vmname       = "linux-vm-"
  vmnameformat  = "%03d"               # %02 gives "VM-Name-01",  %03 gives "VM-Name-001", ...
  network = {
    # "workload-network" = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""] # To use DHCP create Empty list ["",""]; You can also use a CIDR annotation;
    "vDS-VL701" = ["10.70.1.201", "10.70.1.202", "10.70.1.203", "10.70.1.204", "10.70.1.205", "10.70.1.206", "10.70.1.207", "10.70.1.208", "10.70.1.209", "10.70.1.210"] # To use DHCP create Empty list ["",""]; You can also use a CIDR annotation;
    #"vDS-VL701" = ["", "", "", "", "", "", "", "", "", ""] # To use DHCP create Empty list ["",""]; You can also use a CIDR annotation;
    # "vDS-VL703" = ["10.70.3.201", "10.70.3.202", "10.70.3.203"]
  }
  # If fixed IP is used, uncomment ipv4submask, vmgateway and dns_server_list below:
  ipv4submask       = ["24"]
  vmgateway         = "10.70.1.254"
  dns_server_list   = ["192.168.0.10", "192.168.0.1"]
  network_type      = ["vmxnet3"]     # Can be vmxnet3, e1000, e1000e or sriov
  scsi_bus_sharing  = "noSharing"     # Can be set to physicalSharing, virtualSharing or noSharing
  scsi_type         = "lsilogic-sas"  # Can be set to lsilogic, lsilogi-sas or pvscsi
  scsi_controller   = 0               # This will assign OS disk to controller 0
  enable_disk_uuid  = false           # Optionally expose the UUID of the disk to the VM
  firmware          = "bios"           # If the VMs only boot up to a black screen, change this to "bios"
}

output "vmnames" {
  value = module.jonamiki-linux-vm.VM
}

output "vmnameswip" {
  value = module.jonamiki-linux-vm.ip
}
