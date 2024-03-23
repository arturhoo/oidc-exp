resource "google_service_account" "default" {
  account_id   = "oidc-exp-service-account"
  display_name = "OIDC Exp Service Account"
}

resource "google_storage_bucket_iam_binding" "viewer" {
  bucket  = var.gcs_bucket
  role    = "roles/storage.objectViewer"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  workload_identity_pool_id = "oidc-exp-wip-${random_string.suffix.result}"
}

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = local.workload_identity_pool_id
}

resource "google_iam_workload_identity_pool_provider" "trusted_eks_cluster" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "trusted-eks-cluster"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    issuer_uri = aws_eks_cluster.primary.identity[0].oidc[0].issuer
  }
}


resource "google_iam_workload_identity_pool_provider" "trusted_gke_cluster" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "trusted-gke-cluster"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    issuer_uri = "https://${local.gke_issuer_url}"
  }
}

data "google_project" "project" {
  project_id = var.gcp_project_id
}

resource "google_service_account_iam_binding" "binding" {
  service_account_id = google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${local.workload_identity_pool_id}/subject/system:serviceaccount:default:oidc-exp-service-account",
  ]
}
