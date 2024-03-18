terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.20, < 6"
    }

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
