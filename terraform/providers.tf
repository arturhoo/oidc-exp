provider "aws" {
  region  = "us-west-2"
  profile = "oidc-exp-tf"
}


provider "google" {
  project = var.project_id
  region  = var.region
}
