#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="infra-20250121-20260121-0235"
LOCATION="us-central1"
REPO="mega-prod"

# Source images (ECR Public)
BACKEND_SRC="public.ecr.aws/m8q5m4u3/mega:mono-0.1.0-pre-release"
UI_SRC="public.ecr.aws/m8q5m4u3/mega:mega-ui-staging-0.1.0-pre-release"

# Target images (Artifact Registry)
BACKEND_DST="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/mega-backend:mono-0.1.0-pre-release"
UI_DST="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/mega-ui:mega-ui-staging-0.1.0-pre-release"

# Ensure auth for Artifact Registry
gcloud auth configure-docker "${LOCATION}-docker.pkg.dev" --quiet

echo "Pulling source images..."
docker pull "${BACKEND_SRC}"
docker pull "${UI_SRC}"

echo "Tagging for Artifact Registry..."
docker tag "${BACKEND_SRC}" "${BACKEND_DST}"
docker tag "${UI_SRC}" "${UI_DST}"

echo "Pushing to Artifact Registry..."
docker push "${BACKEND_DST}"
docker push "${UI_DST}"

echo "Done."
echo "Backend image: ${BACKEND_DST}"
echo "UI image:      ${UI_DST}"

