resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket
}

resource "aws_s3_object" "s3_object" {
  bucket  = aws_s3_bucket.s3_bucket.id
  key     = "test.txt"
  content = "Hello, from S3!"
}
