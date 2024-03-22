terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.41, < 6"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0, < 5"
    }
  }

  required_version = ">= 1.7"
}
