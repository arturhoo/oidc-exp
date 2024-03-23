resource "google_service_account" "gke_limited_service_account" {
  account_id   = "gke-limited-service-account"
  display_name = "GKE Limited Service Account"
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
    service_account = google_service_account.gke_limited_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

locals {
  gke_issuer_url = "container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_zone}/clusters/oidc-exp-cluster"
}
