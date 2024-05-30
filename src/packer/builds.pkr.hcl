
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
