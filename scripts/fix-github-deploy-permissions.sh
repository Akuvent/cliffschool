# Fix: Permission 'iam.serviceAccounts.getAccessToken' denied
# Run in Cloud Shell: https://shell.cloud.google.com/

PROJECT_ID="cliffschool"
PROJECT_NUMBER="725275517762"
REPO="Akuvent/cliffschool"
SA="github-deployer"
SA_EMAIL="${SA}@${PROJECT_ID}.iam.gserviceaccount.com"
MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

gcloud services enable iamcredentials.googleapis.com sts.googleapis.com firebasehosting.googleapis.com \
  --project="$PROJECT_ID"

# Create SA if missing
gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" 2>/dev/null \
  || gcloud iam service-accounts create "$SA" --project="$PROJECT_ID"

# Create WIF pool + OIDC provider if missing (fix script alone is not enough without these)
gcloud iam workload-identity-pools create github \
  --project="$PROJECT_ID" --location=global \
  --display-name="GitHub Actions" 2>/dev/null || true

gcloud iam workload-identity-pools providers create-oidc github \
  --project="$PROJECT_ID" --location=global \
  --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='${REPO}'" 2>/dev/null || \
gcloud iam workload-identity-pools providers describe github \
  --project="$PROJECT_ID" --location=global \
  --workload-identity-pool=github >/dev/null 2>&1 || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/firebasehosting.admin" \
  --condition=None 2>/dev/null || \
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/firebasehosting.admin"

# Required for WIF impersonation
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$MEMBER"

# Required for token_format: access_token (this fixes the 403)
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --member="$MEMBER"

echo ""
echo "Fixed bindings for ${SA_EMAIL}"
echo "Re-run the failed GitHub Action: Actions -> Deploy to Firebase Hosting on merge -> Re-run"
