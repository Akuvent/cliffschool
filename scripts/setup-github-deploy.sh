# Run once in Google Cloud Shell: https://shell.cloud.google.com/
# Project: cliffschool | Repo: Akuvent/cliffschool

PROJECT_ID="cliffschool"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
REPO="Akuvent/cliffschool"
SA="github-deployer"

gcloud services enable iamcredentials.googleapis.com firebasehosting.googleapis.com \
  --project="$PROJECT_ID"

gcloud iam service-accounts create "$SA" --project="$PROJECT_ID" 2>/dev/null || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/firebasehosting.admin"

gcloud iam workload-identity-pools create github \
  --project="$PROJECT_ID" --location=global \
  --display-name="GitHub Actions" 2>/dev/null || true

gcloud iam workload-identity-pools providers create-oidc github \
  --project="$PROJECT_ID" --location=global \
  --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='${REPO}'" 2>/dev/null || true

gcloud iam service-accounts add-iam-policy-binding "${SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

gcloud iam service-accounts add-iam-policy-binding "${SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="$PROJECT_ID" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

echo ""
echo "Done. PROJECT_NUMBER=${PROJECT_NUMBER}"
echo "Add this to .github/workflows/firebase-hosting-merge.yml if not already set."
