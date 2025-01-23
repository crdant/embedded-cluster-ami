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
