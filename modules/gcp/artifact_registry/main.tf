resource "google_artifact_registry_repository" "this" {
  location      = var.location
  repository_id = var.repo_name
  format        = "DOCKER"
}

