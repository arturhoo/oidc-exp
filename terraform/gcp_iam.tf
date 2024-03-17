resource "google_storage_bucket_iam_binding" "viewer" {
  bucket = var.gcs_bucket
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${google_service_account.default.email}",
  ]
}
