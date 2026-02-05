#!/bin/bash
set -euo pipefail

# Minimal validation script for GCP deployment
# Usage: ./minimal-validation.sh <env>
# Example: ./minimal-validation.sh dev

ENV=${1:-dev}
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || echo "")
REGION="us-central1"

echo "=== Minimal validation for environment: $ENV ==="

if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: Cannot read project_id from terraform output. Run from envs/gcp/$ENV directory."
  exit 1
fi

# 1) Check GKE cluster exists and is running
echo "1. Checking GKE cluster..."
CLUSTER_NAME="mega-gke"
if [[ "$ENV" == "staging" ]]; then
  CLUSTER_NAME="mega-staging"
elif [[ "$ENV" == "prod" ]]; then
  CLUSTER_NAME="mega-prod"
fi

gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" --format="value(status)" > /dev/null
echo "✅ GKE cluster $CLUSTER_NAME exists"

# 2) Get credentials and check node pools
echo "2. Getting credentials and checking node pools..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [[ "$NODE_COUNT" -eq 0 ]]; then
  echo "❌ No nodes found in cluster"
  exit 1
fi
echo "✅ Found $NODE_COUNT nodes"

# 3) Check Cloud SQL (if enabled)
echo "3. Checking Cloud SQL (if enabled)..."
SQL_INSTANCE_NAME="mega-gke-db"
if [[ "$ENV" == "staging" ]]; then
  SQL_INSTANCE_NAME="mega-staging-db"
elif [[ "$ENV" == "prod" ]]; then
  SQL_INSTANCE_NAME="mega-prod-db"
fi

if gcloud sql instances describe "$SQL_INSTANCE_NAME" --project "$PROJECT_ID" --format="value(state)" > /dev/null 2>&1; then
  SQL_STATE=$(gcloud sql instances describe "$SQL_INSTANCE_NAME" --project "$PROJECT_ID" --format="value(state)")
  echo "✅ Cloud SQL instance $SQL_INSTANCE_NAME state: $SQL_STATE"
else
  echo "ℹ️ Cloud SQL instance $SQL_INSTANCE_NAME not found (may be disabled)"
fi

# 4) Check Redis (if enabled)
echo "4. Checking Redis (if enabled)..."
REDIS_INSTANCE_NAME="mega-gke-redis"
if [[ "$ENV" == "staging" ]]; then
  REDIS_INSTANCE_NAME="mega-staging-redis"
elif [[ "$ENV" == "prod" ]]; then
  REDIS_INSTANCE_NAME="mega-prod-redis"
fi

if gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region "$REGION" --project "$PROJECT_ID" --format="value(state)" > /dev/null 2>&1; then
  REDIS_STATE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region "$REGION" --project "$PROJECT_ID" --format="value(state)")
  echo "✅ Redis instance $REDIS_INSTANCE_NAME state: $REDIS_STATE"
else
  echo "ℹ️ Redis instance $REDIS_INSTANCE_NAME not found (may be disabled)"
fi

# 5) Check GCS bucket (if enabled)
echo "5. Checking GCS bucket (if enabled)..."
BUCKET_NAME="mega-gke-storage"
if [[ "$ENV" == "staging" ]]; then
  BUCKET_NAME="mega-staging-storage"
elif [[ "$ENV" == "prod" ]]; then
  BUCKET_NAME="mega-prod-storage"
fi

if gsutil ls "gs://$BUCKET_NAME" > /dev/null 2>&1; then
  echo "✅ GCS bucket $BUCKET_NAME exists"
else
  echo "ℹ️ GCS bucket $BUCKET_NAME not found (may be disabled)"
fi

# 6) Check Artifact Registry (if enabled)
echo "6. Checking Artifact Registry (if enabled)..."
REPO_NAME="orion-worker"
if [[ "$ENV" == "staging" ]]; then
  REPO_NAME="orion-worker-staging"
elif [[ "$ENV" == "prod" ]]; then
  REPO_NAME="orion-worker-prod"
fi

if gcloud artifacts repositories describe "$REPO_NAME" --location "$REGION" --project "$PROJECT_ID" > /dev/null 2>&1; then
  echo "✅ Artifact Registry repository $REPO_NAME exists"
else
  echo "ℹ️ Artifact Registry repository $REPO_NAME not found (may be disabled)"
fi

# 7) Check Logging/Monitoring APIs enabled
echo "7. Checking Logging/Monitoring APIs..."
LOGGING_ENABLED=$(gcloud services list --enabled --project "$PROJECT_ID" | grep "logging.googleapis.com" || echo "")
MONITORING_ENABLED=$(gcloud services list --enabled --project "$PROJECT_ID" | grep "monitoring.googleapis.com" || echo "")

if [[ -n "$LOGGING_ENABLED" ]]; then
  echo "✅ Cloud Logging API enabled"
else
  echo "❌ Cloud Logging API not enabled"
fi

if [[ -n "$MONITORING_ENABLED" ]]; then
  echo "✅ Cloud Monitoring API enabled"
else
  echo "❌ Cloud Monitoring API not enabled"
fi

echo "=== Minimal validation completed for $ENV ==="
