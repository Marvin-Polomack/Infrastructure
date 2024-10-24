terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.97.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "5.72.1"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.6"
    }
  }

  backend "s3" {
    bucket = "freelance-tfstate"
    key    = "freelance.tfstate"
    region = "eu-west-3"
  }

}