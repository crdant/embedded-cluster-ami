packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 1.4.2"
    }
  }
}
