output "repository" {
  value = google_artifact_registry_repository.this.id
}

output "repository_url" {
  value = "${var.location}-docker.pkg.dev/${google_artifact_registry_repository.this.project}/${google_artifact_registry_repository.this.repository_id}"
}

