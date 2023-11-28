locals {
  user-data = templatefile("${var.project_root}/src/packer/templates/user-data.tmpl",
                             {
                               application = var.application
                               install_dir = "/opt/${var.application}"
                               default_admin_console_password = var.admin_console_password
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
  ami_name      = "${var.application}-ubuntu-22.04-lts"
  source_ami    = var.source_ami
  instance_type = var.instance_type
  
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = var.volume_size
  }

  access_key = var.access_key_id
  secret_key = var.secret_access_key
  region     = var.region

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

}
