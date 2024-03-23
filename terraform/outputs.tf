output "gcp_pool_suffix" {
  value       = random_string.suffix.result
  description = "suffix value of the GCP Pool to be used in the K8s manifests"
}
