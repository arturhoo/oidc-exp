variable "profile" {
  description = "AWS profile, to be used for the terraform state"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for the test"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}
