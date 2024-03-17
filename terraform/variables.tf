variable "aws_profile" {
  description = "AWS profile, to be used for the terraform state"
}

variable "gcp_project_id" {
  description = "project id"
}

variable "gcp_region" {
  description = "GCP region"
}

variable "gcp_zone" {
  description = "GCP zone"
}

variable "gcs_bucket" {
  description = "GCS bucket"
}

variable "s3_bucket" {
  description = "S3 bucket for the test"
}

variable "aws_region" {
  description = "AWS region"
}
