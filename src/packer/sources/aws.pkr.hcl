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
