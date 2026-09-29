#!/usr/bin/env bash
# Build a second identity from scratch, the certificate way.
#
# Everything here happens on a real cluster and is safe to undo. The point is
# to watch a username and a group come into existence WITHOUT Kubernetes ever
# creating a user object — because it cannot.
#
#   bash create-user-certificate.sh
#
# Requires: kubectl with admin access, and openssl.
set -euo pipefail

USER_NAME="james"
GROUP_NAME="developers"
NAMESPACE="dev"

echo "== 1. Generate a PRIVATE KEY. This never leaves this machine =="
openssl genrsa -out "${USER_NAME}.key" 2048

echo
echo "== 2. Create a Certificate Signing Request =="
echo "   CN = the USERNAME Kubernetes will see"
echo "   O  = a GROUP (repeat -subj O= entries for several)"
openssl req -new -key "${USER_NAME}.key" -out "${USER_NAME}.csr" \
  -subj "/CN=${USER_NAME}/O=${GROUP_NAME}"

openssl req -in "${USER_NAME}.csr" -noout -subject    # read it back

echo
echo "== 3. Wrap the CSR in a Kubernetes CertificateSigningRequest object =="
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER_NAME}
spec:
  request: $(base64 -w0 < "${USER_NAME}.csr" 2>/dev/null || base64 < "${USER_NAME}.csr" | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400          # 1 day — remember there is NO REVOCATION
  usages:
  - client auth                     # the extended key usage the API server requires
EOF

kubectl get csr "${USER_NAME}"      # CONDITION: Pending

echo
echo "== 4. An ADMINISTRATOR approves it. This is the actual control =="
echo "   Anyone can ASK for CN=system:admin,O=system:masters — approval is what stops them."
kubectl certificate approve "${USER_NAME}"
kubectl get csr "${USER_NAME}"      # CONDITION: Approved,Issued

echo
echo "== 5. Collect the signed certificate =="
kubectl get csr "${USER_NAME}" -o jsonpath='{.status.certificate}' | base64 -d > "${USER_NAME}.crt"
openssl x509 -in "${USER_NAME}.crt" -noout -subject -issuer -dates

echo
echo "== 6. Wire it into a kubeconfig context =="
CLUSTER=$(kubectl config view -o jsonpath='{.clusters[0].name}')

kubectl config set-credentials "${USER_NAME}" \
  --client-certificate="${USER_NAME}.crt" \
  --client-key="${USER_NAME}.key" \
  --embed-certs=true               # inline the DATA, not a file path

kubectl config set-context "${USER_NAME}@${CLUSTER}" \
  --cluster="${CLUSTER}" --user="${USER_NAME}" --namespace="${NAMESPACE}"

echo
echo "== Done. The identity now exists — but NOTHING was created in Kubernetes =="
kubectl config get-contexts
echo
echo "Try it (expect FORBIDDEN — authenticated, but no RBAC bindings yet):"
echo "  kubectl --context=${USER_NAME}@${CLUSTER} get pods"
echo "  kubectl --context=${USER_NAME}@${CLUSTER} auth whoami"
echo "  kubectl --context=${USER_NAME}@${CLUSTER} auth can-i --list"
echo
echo "That 403 is the whole point of part 1: authentication SUCCEEDED and"
echo "authorization DENIED. Roles and bindings are the next chapter."
echo
echo "Clean up:"
echo "  kubectl delete csr ${USER_NAME}"
echo "  kubectl config delete-context ${USER_NAME}@${CLUSTER}"
echo "  kubectl config delete-user ${USER_NAME}"
echo "  rm -f ${USER_NAME}.key ${USER_NAME}.csr ${USER_NAME}.crt"
