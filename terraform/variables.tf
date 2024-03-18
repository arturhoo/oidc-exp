variable "aws_profile" {
  description = "AWS profile, to be used for the terraform state"
  type        = string
}

variable "gcp_project_id" {
  description = "project id"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
}

variable "gcs_bucket" {
  description = "GCS bucket"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for the test"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_zone1" {
  description = "AWS zone 1"
  type        = string
}

variable "aws_zone2" {
  description = "AWS zone 2"
  type        = string
}
