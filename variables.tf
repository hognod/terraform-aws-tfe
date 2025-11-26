variable "ami_id" {
  type        = string
  description = <<-EOT
    UbuntuOS only

    ubuntu 20.04 : ami-09eb4311cbaecf89d
    ubuntu 22.04 : ami-05d2438ca66594916
  EOT
}

variable "os_user" {
  type    = string
  default = "ubuntu"
}

variable "instance_type" {
  type = string
}

variable "volume_size" {
  type = string
}

//eks node group
variable "node_group_instance_type" {
  type = string
}

variable "node_group_ami_type" {
  type = string
}

variable "node_group_disk_size" {
  type = string
}

//elasticache
variable "elasticache_node_type" {
  type = string
}

//variables sets
variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
  type = string
}