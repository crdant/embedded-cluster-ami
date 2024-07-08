locals {
  user-data = templatefile("${var.project_root}/src/packer/templates/user-data.tmpl",
                             {
                               application = var.application
                               channel = var.channel
                               install_dir = "/opt/${var.application}"
                               replicated_api_token = var.replicated_api_token
                               api_token = var.replicated_api_token
                             }
                          )
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "embedded-cluster" {
  ami_name      = "${var.application}-${var.channel}-ubuntu-22.04-lts"
  source_ami    = var.source_ami
  instance_type = var.instance_type
  
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = var.volume_size
  }

  access_key = var.access_key_id
  secret_key = var.secret_access_key
  region     = var.build_region

  ami_regions     = var.regions
  ami_users       = [
    "177217428600",
    "429114214526"
  ]

  ssh_username         = "ubuntu"

  user_data = local.user-data
}

build {
  sources = ["source.amazon-ebs.embedded-cluster"]

  provisioner "shell" {
    pause_before = "20s"
    inline = [
      "cloud-init status --wait",
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
    homedir: "/opt/${var.application}"
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

  provisioner "shell" {
    inline = [
      "export GLOBIGNORE=\".:..\"",
      "rm -rf /home/ubuntu/.ssh",
      "rm -rf /home/ubuntu/*"
    ]
  }
}
