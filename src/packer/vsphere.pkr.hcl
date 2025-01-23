locals {
  autoinstall = templatefile("${var.project_root}/src/packer/templates/autoinstall.tmpl",{})
}

source "vsphere-iso" "embedded-cluster" {
  vm_name      = "${var.application}-${var.channel}-ubuntu-22.04-lts"

  CPUs                 = var.numvcpus
  RAM                  = var.memsize
  disk_controller_type = ["pvscsi"]

  iso_url      = var.source_iso
  iso_checksum = var.source_iso_checksum

  network_adapters {
    network = var.vsphere_network
  }

  storage {
    disk_size = var.volume_size
    disk_thin_provisioned = true
  }

  ssh_username         = "ubuntu"
  ssh_timeout          = "10m"
 
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  datastore           = var.vsphere_datastore

  cd_content = {
    "/meta-data" = ""
    "/user-data" = local.autoinstall # join(" ", [ local.autoinstall, local.user-data ])
  }

  boot_command = [
    // This waits for 3 seconds, sends the "c" key, and then waits for another 3 seconds. In the GRUB boot loader, this is used to enter command line mode.
    "<wait3s>c<wait3s>",
    // This types a command to load the Linux kernel from the specified path with the 'autoinstall' option and the value of the 'data_source_command' local variable.
    // The 'autoinstall' option is used to automate the installation process.
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net\"",
    // This sends the "enter" key and then waits. This is typically used to execute the command and give the system time to process it.
    "<enter><wait>",
    // This types a command to load the initial RAM disk from the specified path.
    "initrd /casper/initrd",
    // This sends the "enter" key and then waits. This is typically used to execute the command and give the system time to process it.
    "<enter><wait>",
    // This types the "boot" command. This starts the boot process using the loaded kernel and initial RAM disk.
    "boot",
    // This sends the "enter" key. This is typically used to execute the command.
    "<enter>"
  ]

  export {
    name  = "${var.application}-${var.channel}-ubuntu-22.04-lts"
    force = true

    output_directory  = var.output_directory
  }
}
