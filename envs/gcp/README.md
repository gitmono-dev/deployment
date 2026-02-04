# Mega GCP Deployment

This directory contains Terraform configurations for deploying Mega on Google Cloud Platform (GCP).  
It mirrors the structure of the AWS deployment while adapting to GCP-native resources and conventions.

## Directory Structure

```
deployment/envs/gcp/
├── dev/                 # Development environment
├── staging/             # Staging environment
├── prod/                # Production environment
└── README.md            # This file
```

Each environment directory contains:

- `main.tf`              – Main Terraform configuration
- `variables.tf`         – Variable definitions
- `terraform.tfvars.example` – Example variable values
- `providers.tf`         – GCP provider configuration
- `versions.tf`          – Terraform and provider versions

## Prerequisites

### Required Tools
- Terraform (>= 1.0)
- gcloud CLI
- kubectl (for post-deployment validation)

### Required Permissions
Your GCP account or service account must be able to create:
- VPC / Subnets / Firewall rules
- GKE clusters and node pools
- Cloud SQL (PostgreSQL / MySQL)
- Memorystore (Redis)
- Filestore (NFS)
- Artifact Registry
- Cloud Logging / Monitoring
- IAM service accounts and bindings

### Required APIs
Enable the following APIs in your project:

```bash
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  redis.googleapis.com \
  file.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com
```

## Quick Start

### 1) Clone and Prepare

```bash
git clone <repository-url>
cd deployment/envs/gcp/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_id = "your-gcp-project-id"
base_domain = "dev.gitmono.com"

# Optional: override defaults
# region = "us-central1"
# zone = "us-central1-b"

# Storage (mapped from AWS s3_*)
storage_bucket = "mega-dev-storage"

# Database
db_username = "mega_user"
db_password = "your-db-password"
db_schema = "mega_dev"

# Rails/UI
rails_master_key = "your-rails-master-key"
rails_env = "development"
ui_env = "dev"

# Application
app_suffix = "dev"
app_service_name = "mega-app"
app_image = "us-central1-docker.pkg.dev/your-gcp-project-id/orion-worker/mega:latest"
app_container_port = 80
app_replicas = 1

# Ingress
ingress_name = "mega-ingress"
ingress_static_ip_name = "mega-dev-ip"
ingress_managed_certificate_domains = ["dev.gitmono.com"]
ingress_rules = [
  {
    host         = "dev.gitmono.com"
    service_name = "mega-app"
    service_port = 80
  }
]

# Service Accounts (optional)
iam_service_accounts = {
  mega-app = {
    display_name = "Mega App Service Account"
    roles        = ["roles/cloudsql.client", "roles/storage.objectViewer"]
    wi_bindings = [
      {
        namespace                = "default"
        k8s_service_account_name = "mega-app-sa"
      }
    ]
  }
}

# Feature flags
enable_build_env = true
enable_gcs = false
enable_cloud_sql = false
enable_redis = false
enable_filestore = false
enable_apps = false
enable_ingress = false
enable_logging = true
enable_monitoring = true
enable_alerts = false

# Orion Worker (optional)
enable_orion_worker = false
# orion_worker_image = "public.ecr.aws/m8q5m4u3/mega:orion-client-0.1.0-pre-release-amd64"
# orion_worker_server_ws = "wss://orion.gitmono.com/ws"
# orion_worker_nodepool_name = "build-default"
```

### 2) Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3) Get GKE Credentials

```bash
gcloud container clusters get-credentials mega-gke --region us-central1 --project YOUR_PROJECT_ID
```

### 4) Verify Deployment

#### Basic Resource Validation

```bash
bash ../../gcp/e2e/minimal-validation.sh dev
```

#### Orion Worker E2E (if enabled)

```bash
kubectl -n orion-worker get ds/orion-worker
kubectl -n orion-worker get pods -l app=orion-worker -o wide

# Connectivity check
kubectl apply -f ../../gcp/e2e/connectivity-check-job.yaml
kubectl -n orion-worker wait --for=condition=complete job/orion-worker-connectivity-check --timeout=120s
kubectl -n orion-worker logs job/orion-worker-connectivity-check

# Task execution test
kubectl apply -f ../../gcp/e2e/task-e2e-trigger-job.yaml
kubectl -n orion-worker logs -f job/orion-task-e2e-trigger
```

## Architecture Overview

### Core Components

| Component | GCP Resource | AWS Equivalent |
|-----------|--------------|----------------|
| VPC / Subnets | `google_compute_network` / `google_compute_subnetwork` | VPC / Subnets |
| NAT / Router | `google_compute_router_nat` / `google_compute_router` | NAT Gateway |
| Firewall | `google_compute_firewall` | Security Groups |
| Container Runtime | GKE (`google_container_cluster`) | ECS / Fargate |
| Load Balancer | GKE Ingress / GCLB | ALB |
| Object Storage | GCS (`google_storage_bucket`) | S3 |
| File Storage | Filestore (`google_filestore_instance`) | EFS |
| Relational DB | Cloud SQL (`google_sql_database_instance`) | RDS |
| Cache | Memorystore (`google_redis_instance`) | ElastiCache |
| Container Registry | Artifact Registry (`google_artifact_registry_repository`) | ECR |
| Logging / Monitoring | Cloud Logging / Monitoring | CloudWatch |
| IAM | Service Accounts / Workload Identity | IAM Roles / Policies |

### Build Execution Environment (#1841)

- **Orion Worker**: Deployed as a DaemonSet on a dedicated node pool (`taint: dedicated=orion-build`)
- **Node Pool**: `n2-standard-8` with `dedicated=orion-build:NoSchedule`
- **Storage**: HostPath volumes for `/data` and `/workspace`
- **Connectivity**: Outbound internet via Cloud NAT (public nodes) or Private Service Connect (private nodes)

## Variables Reference

### Required Variables

| Name | Description | Example |
|------|-------------|---------|
| `project_id` | GCP project ID | `infra-20250121-20260121-0235` |
| `base_domain` | Base domain for services | `dev.gitmono.com` |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| `region` | GCP region | `us-central1` |
| `zone` | GCP zone for zonal resources | `""` |
| `name_prefix` | Prefix for resource names | `mega` |
| `enable_build_env` | Enable GKE and build environment | `true` |
| `enable_gcs` | Enable GCS bucket | `false` |
| `enable_cloud_sql` | Enable Cloud SQL | `false` |
| `enable_redis` | Enable Memorystore Redis | `false` |
| `enable_filestore` | Enable Filestore | `false` |
| `enable_apps` | Enable application services | `false` |
| `enable_ingress` | Enable Ingress controller | `false` |
| `enable_orion_worker` | Enable Orion Worker DaemonSet | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `gke_cluster_name` | GKE cluster name |
| `gke_cluster_location` | GKE cluster location |
| `artifact_registry_repo` | Artifact Registry repository |
| `pg_endpoint` | Cloud SQL database endpoint (if enabled) |
| `valkey_endpoint` | Redis endpoint (if enabled) |
| `alb_dns_name` | Ingress IP/hostname (if enabled) |
| `project_id` | GCP project ID |

## Environment Differences

| Variable | Dev | Staging | Prod |
|----------|-----|---------|------|
| `name_prefix` | `mega` | `mega-staging` | `mega-prod` |
| `subnet_cidr` | `10.20.0.0/16` | `10.30.0.0/16` | `10.40.0.0/16` |
| `pods_secondary_range` | `10.21.0.0/16` | `10.31.0.0/16` | `10.41.0.0/16` |
| `services_secondary_range` | `10.22.0.0/16` | `10.32.0.0/16` | `10.42.0.0/16` |
| `cluster_name` | `mega-gke` | `mega-staging` | `mega-prod` |
| `node_machine_type` | `n2-standard-8` | `e2-standard-4` | `e2-standard-8` |
| `node_min_count` | `0` | `1` | `2` |
| `node_max_count` | `10` | `5` | `20` |
| `cloud_sql_availability_type` | `ZONAL` | `ZONAL` | `REGIONAL` |
| `cloud_sql_deletion_protection` | `false` | `false` | `true` |
| `redis_memory_size_gb` | `1` | `2` | `4` |
| `app_replicas` | `1` | `2` | `3` |
| `enable_alerts` | `false` | `false` | `true` |

## Best Practices

### Security
- Use Workload Identity instead of service account keys
- Enable private endpoints for databases in production
- Apply least privilege IAM roles
- Do not commit `terraform.tfvars` with real credentials

### Cost Management
- Use smaller instance types in dev/staging
- Enable deletion protection only in production
- Set appropriate autoscaling limits
- Clean up resources when not in use

### State Management
- Use remote state storage (GCS backend)
- Lock state to prevent concurrent modifications
- Consider state isolation per environment

## Troubleshooting

### Common Issues

1. **API not enabled**: Ensure all required APIs are enabled in your project
2. **Permission denied**: Check IAM permissions for the service account
3. **Quota exceeded**: Request quota increases for resources like CPUs or IP addresses
4. **Resource conflicts**: Check for naming conflicts with existing resources
5. **Terraform state issues**: Use `terraform state list` and `terraform state rm` if needed

### Cleanup

```bash
terraform destroy
```

### Validation Scripts

- `../../gcp/e2e/minimal-validation.sh` – Basic resource validation
- `../../gcp/e2e/connectivity-check-job.yaml` – Network connectivity test
- `../../gcp/e2e/task-e2e-trigger-job.yaml` – End-to-end task execution test

## Contributing

When contributing to this deployment:

1. Follow the existing module structure
2. Use consistent naming conventions
3. Update documentation for new features
4. Test changes in a non-production environment first
5. Ensure all Terraform code is formatted (`terraform fmt`)
6. Validate configuration (`terraform validate`)

## References

- [GCP Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Memorystore Documentation](https://cloud.google.com/memorystore/docs)
- [Filestore Documentation](https://cloud.google.com/filestore/docs)
