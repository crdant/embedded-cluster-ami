build {
  sources = [
    "source.amazon-ebs.embedded-cluster",
    "source.vsphere-iso.embedded-cluster"
  ]

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
