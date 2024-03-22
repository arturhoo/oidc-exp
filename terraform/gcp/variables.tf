variable "project_id" {
  description = "project id"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "gcs_bucket" {
  description = "GCS bucket"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile, to be used for the terraform state"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for the test"
  type        = string
}
