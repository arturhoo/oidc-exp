terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.20, < 6"
    }
  }

  required_version = ">= 1.7"
}