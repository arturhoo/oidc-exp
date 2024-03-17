resource "google_service_account" "default" {
  account_id   = "oidc-exp-service-account"
  display_name = "OIDC Exp Service Account"
}

data "google_container_engine_versions" "gke_version" {
  location       = var.gcp_region
  version_prefix = "1.29."
}

resource "google_container_cluster" "primary" {
  name                = "oidc-exp-cluster"
  location            = var.gcp_zone
  deletion_protection = false
  min_master_version  = data.google_container_engine_versions.gke_version.release_channel_latest_version["REGULAR"]

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "oidc-exp-node-pool"
  location   = var.gcp_zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  version = data.google_container_engine_versions.gke_version.release_channel_latest_version["REGULAR"]

  node_config {
    preemptible  = true
    machine_type = "t2a-standard-1"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

resource "google_service_account_iam_binding" "service_account_iam_binding" {
  service_account_id = google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.gcp_project_id}.svc.id.goog[deafult/default]"]
}

