resource "google_storage_bucket" "gcs_bucket" {
  name     = var.gcs_bucket
  location = var.gcp_region
}

resource "google_storage_bucket_object" "gcs_object" {
  bucket  = google_storage_bucket.gcs_bucket.name
  name    = "test.txt"
  content = "Hello, from GCS!"
}
