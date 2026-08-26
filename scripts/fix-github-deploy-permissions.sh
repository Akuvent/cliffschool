# Fix: Permission 'iam.serviceAccounts.getAccessToken' denied
# Run in Cloud Shell: https://shell.cloud.google.com/

PROJECT_ID="cliffschool"
PROJECT_NUMBER="725275517762"
REPO="Akuvent/cliffschool"
SA="github-deployer"
SA_EMAIL="${SA}@${PROJECT_ID}.iam.gserviceaccount.com"
MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

gcloud services enable iamcredentials.googleapis.com sts.googleapis.com \
  --project="$PROJECT_ID"

# Create SA if missing
gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" 2>/dev/null \
  || gcloud iam service-accounts create "$SA" --project="$PROJECT_ID"

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
