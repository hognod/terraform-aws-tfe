# Terraform Binary Install
terraform {
  version = "1.14.3"
}

# Define which provider plugins are to be included
providers {
  # Include the newest "aws" provider version in the 1.0 series.
  aws = {
    versions = ["~> 6.27.0"]
  }

  ncloud = {
    source = "NaverCloudPlatform/ncloud"
    versions = ["= 4.0.4"]
  }

  tfe = {
    versions = ["= 0.68.0"]
  }

  time = {
    versions = ["= 0.13.1"]
  }

  external = {
    versions = ["= 2.3.5"]
  }
}