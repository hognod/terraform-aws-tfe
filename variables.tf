//variables sets
variable "access_key" {}
variable "secret_key" {}
variable "region" {}

variable "prefix" {
  type = string
  default = "tfe"
}

# Instance
variable "instance_ami_id" {
  type        = string
  description = <<-EOT
    UbuntuOS only

    ubuntu 20.04 : ami-09eb4311cbaecf89d
    ubuntu 22.04 : ami-05d2438ca66594916
  EOT
}

variable "windows_instance_ami_id" {
  type        = string
  description = <<-EOT
    Microsoft Windows Server 2022 Base : ami-091f0555283ad8033
    Microsoft Windows Server 2025 Base : ami-03bf0c45be3d883bb
  EOT
}

variable "instance_user" {
  type    = string
  default = "ubuntu"
}

variable "windows_instance_user" {
  type = string
  default = "Administrator"
}

variable "windows_instance_password" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "windows_instance_type" {
  type = string
}

variable "instance_volume_size" {
  type = string
}

variable "windows_instance_volume_size" {
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
variable "db_name" {
  type = string
}

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
variable "tfe_license" {
  type = string
}

variable "tfe_hostname" {
  type = string
}

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

variable "tfe_agent_kube_svc_account" {
  type = string
}

# ETC
variable "tfe_domain" {
  type = string
}

variable "gitlab_domain" {
  type = string
}