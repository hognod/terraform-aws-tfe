# Define which provider plugins are to be included
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

  helm = {
    versions = ["= 3.1.1"]
  }

  kubernetes = {
    versions = ["= 3.0.1"]
  }

  random = {
    versions = ["= 3.8.1"]
  }

  tls = {
    versions = ["= 4.2.1"]
  }
  
  opensearch = {
    source  = "opensearch-project/opensearch"
    versions = ["= 2.3.2"]
  }
}