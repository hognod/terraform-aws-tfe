//variables sets
variable "access_key" {}
variable "secret_key" {}
variable "region" {}

# Instance
variable "instance_ami_id" {
  type        = string
  description = <<-EOT
    UbuntuOS only

    ubuntu 20.04 : ami-09eb4311cbaecf89d
    ubuntu 22.04 : ami-05d2438ca66594916
  EOT
}

variable "instance_user" {
  type    = string
  default = "ubuntu"
}

variable "instance_type" {
  type = string
}

variable "instance_volume_size" {
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

//rds
variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_storage_size" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

# tfe
variable "tfe_kube_namespace" {
  type = string
}

variable "tfe_kube_svc_account" {
 type = string 
}

variable "tfe_lb_controller_kube_namespace" {
  type = string
}

variable "tfe_lb_controller_kube_svc_account" {
  type = string
}