locals {
  user-data = templatefile("${var.project_root}/src/packer/templates/user-data.tmpl",
                             {
                               application = var.application
                               channel = var.channel
                               install_dir = "/opt/${var.application}"
                               default_admin_console_password = var.admin_console_password
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
      "rm /home/ubuntu/.ssh/authorized_keys"
    ]
  }
}
