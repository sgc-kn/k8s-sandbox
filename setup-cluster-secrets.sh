#!/usr/bin/env bash

set -eEuo pipefail



NAMESPACE=cluster-secrets
ENVIRONMENT=${1:-dev}

confirm () {
  read -p "(Enter to continue, CTRL+C otherwise)"
}

echo "We're going to configure the cluster secrets for the __${ENVIRONMENT}__ environment. Okay?"
confirm

echo "I'm going to delete the entire namespace cluster-secrets. Okay?"
confirm
kubectl delete namespace ${NAMESPACE} || true
kubectl create namespace ${NAMESPACE}

resource () {
  cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: infisical-platform-auth
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  clientId: ${CLIENT_ID}
  clientSecret: ${CLIENT_SECRET}
EOF
}

cat <<EOF
Manual steps:
- Login to https://eu.infisical.com
- Navigate to Organization Access Control > Tab Identities:
  https://eu.infisical.com/organization/access-management?selectedTab=identities
- Select identity $ENVIRONMENT-cluster
- Select pre-configured authentication method "Universal Auth"
- Delete redundant client secrets (especially for prod-cluster)
- Create a new client secret
- Paste below hit enter
- Copy and paste the client id
EOF
read -p "client secret: " CLIENT_SECRET
read -p "client id:     " CLIENT_ID
echo '---'
resource
echo '---'
echo "I'm going to kubectl apply this resource. Okay?"
confirm
resource | kubectl apply -f -
