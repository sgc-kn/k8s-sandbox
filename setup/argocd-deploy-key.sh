#!/usr/bin/env bash

set -eEuo pipefail

TEMP_DIR=$(mktemp -d)
KEY_NAME="$TEMP_DIR/id"
REPO_URL="git@github.com:sgc-kn/infra.git"
COMMENT="argocd@${1:-$USER.$HOST}"

# Ensure cleanup on exit, error, interrupt, and termination
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT ERR SIGINT SIGTERM

# Generate an Ed25519 SSH keypair without a passphrase
ssh-keygen -t ed25519 -N "" -C "$COMMENT" -f "$KEY_NAME" -q

# Read the private key, properly indented for YAML
PRIVATE_KEY=$(sed 's/^/    /' "$KEY_NAME")

resource () {
  cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: private-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: $REPO_URL
  sshPrivateKey: |
$PRIVATE_KEY
EOF
}

echo "kubectl apply ..."
resource | kubectl apply -f -

echo
echo "setup the following public key for repository read access"
echo
cat "$KEY_NAME.pub"
