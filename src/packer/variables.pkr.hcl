variable "project_root" {
  type = string
}

variable "application" {
  type = string
}

variable "channel" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "shadow" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "source_ami" {
  type = string
}

variable "source_iso" {
  type    = string
}

variable "source_iso_checksum" {
  type    = string
}

variable "access_key_id" {
  type = string
}

variable "secret_access_key" {
  type = string
}

variable "build_region" {
  type = string
  default = "us-west-2"
}

variable "regions" {
  type = list(string)
}

variable "replicated_api_token" {
  type = string
}

variable "boot_wait" {
  type    = string
  default = "5s"
}

variable "memsize" {
  type    = string
  default = "2048"
}

variable "numvcpus" {
  type    = string
  default = "2"
}

variable "output_directory" {
  type = string
}

variable "vsphere_username" {
  type    = string
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_server" {
  type = string
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

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
