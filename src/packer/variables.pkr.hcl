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
  default = "us-west-2"
}
