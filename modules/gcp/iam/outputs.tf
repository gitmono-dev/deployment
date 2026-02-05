output "service_accounts" {
  description = "Created service accounts with emails and names"
  value = {
    for k, v in google_service_account.this : k => {
      email = v.email
      name  = v.name
    }
  }
}

output "workload_identity_bindings" {
  description = "Workload Identity bindings (K8s SA -> GCP SA)"
  value = {
    for k, v in google_service_account_iam_member.workload_identity : k => {
      gcp_sa_email = google_service_account.this[split(":", k)[0]].email
      k8s_ns       = split(":", k)[1]
      k8s_sa       = split(":", k)[2]
    }
  }
}

