provider "aws" {
  region = "us-west-2" # Default provider configuration in config file
}


terraform {
  # backend "s3" {
  #   bucket       = "terraform-temp-state-storage-425871937"
  #   key          = "path/to/terraform.tfstate" # e.g., "dev/terraform.tfstate"
  #   region       = "us-east-1"                 # e.g., "us-east-1"
  #   encrypt      = true                        # Recommended for security
  #   use_lockfile = true
  # }

  backend "local" {
    path = "terraform.tfstate"
  }

  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.25.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}