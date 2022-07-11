# Configure the AWS Provider
# Provisioner is not good for automation
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "vscode"
}

