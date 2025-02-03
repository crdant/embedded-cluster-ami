locals {
  autoinstall       = templatefile("${var.project_root}/src/packer/templates/autoinstall.tmpl", {
                              application = var.application,
                              authorized-keys = yamlencode(var.authorized_keys),
                              user-data = local.user-data
                            })
  installer-service = templatefile("${var.project_root}/src/packer/templates/installer.service.tmpl", {
                              application = var.application
                            })
  install-script    = templatefile("${var.project_root}/src/packer/templates/install.sh.tmpl", {
                              application = var.application
                            })
}

source "vsphere-iso" "embedded-cluster" {
  vm_name      = "${var.application}-${var.channel}-ubuntu-22.04-lts"

  CPUs     = var.numvcpus
  RAM      = var.memsize

  iso_url      = var.source_iso
  iso_checksum = var.source_iso_checksum

  network_adapters {
    network = var.vsphere_network
  }

  disk_controller_type = ["pvscsi"]
  storage {
    disk_size = var.volume_size * 1024
    disk_thin_provisioned = false
  }

  ssh_username   = "ubuntu"
  ssh_timeout    = "30m"
  ssh_agent_auth = true
 
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  datastore           = var.vsphere_datastore

  cd_label = "CIDATA"
  cd_content = {
    "/meta-data" = ""
    "/user-data" = local.autoinstall 
  }

  boot_command = [
    // This waits for 3 seconds, sends the "c" key, and then waits for another 3 seconds. In the GRUB boot loader, this is used to enter command line mode.
    "<wait3s>c<wait3s>",
    // This types a command to load the Linux kernel from the specified path with the 'autoinstall' option and the value of the 'data_source_command' local variable.
    // The 'autoinstall' option is used to automate the installation process.
    "linux /casper/vmlinuz --- autoinstall",
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
    output_directory  = join("/", [ var.output_directory, "${var.application}-${var.channel}-ubuntu-22.04-lts"])
  }
}

build {
  sources = [
    "source.vsphere-iso.embedded-cluster"
  ]

  provisioner "shell" {
    pause_before = "20s"
    inline = [
      "sudo cloud-init status --wait",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo cloud-init clean -l",
    ]
  }

  provisioner "shell" {
    inline = [
      <<SCRIPT
sudo bash -c 'cat <<DEFAULT_USER > /etc/cloud/cloud.cfg.d/99_default_user.cfg
#cloud-config
system_info:
  default_user:
    name: ${var.application}
    uid: 1118
    no_create_home: true
    homedir: "/var/lib/${var.application}"
    groups:
    - users
    - sudo
    - adm
    - ssher
    sudo: 
    - ALL=(ALL) NOPASSWD:ALL 
    lock_passwd: true
DEFAULT_USER
chown root:root /etc/cloud/cloud.cfg.d/99_default_user.cfg
chmod 0644 /etc/cloud/cloud.cfg.d/99_default_user.cfg
'
SCRIPT
    ]
  }

  provisioner "file" {
    content = local.install-script
    destination = "/tmp/install.sh"
  }

  provisioner "file" {
    content = local.installer-service
    destination = "/tmp/${var.application}-installer.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/${var.application}-installer.service /etc/systemd/system",
      "sudo mv /tmp/install.sh /var/lib/${var.application}/install.sh",
      "sudo chown 1118:1118 /var/lib/${var.application}/install.sh",
      "sudo chmod 755 /var/lib/${var.application}/install.sh",
      "sudo systemctl enable ${var.application}-installer.service"
    ]
  }

  provisioner "shell" {
    inline = [
      "export GLOBIGNORE=\".:..\"",
      "sudo rm -rf /home/ubuntu/.ssh",
      "sudo rm -rf /home/ubuntu/*",
      "sudo chsh -s /usr/sbin/nologin ubuntu"
    ]
  }
}
