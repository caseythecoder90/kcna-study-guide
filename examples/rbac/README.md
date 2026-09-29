# RBAC — identity

Companion script for [`05-02 RBAC part 1`](../../notes/05-kubernetes-deep-dive/02-rbac-identity-and-kubeconfig.md).

| File | What it does |
|---|---|
| [`create-user-certificate.sh`](create-user-certificate.sh) | Builds a second identity from scratch: private key → CSR → Kubernetes `CertificateSigningRequest` → admin approval → signed certificate → a new kubeconfig context |

```bash
bash create-user-certificate.sh
```

Needs admin access to a cluster and `openssl`. Everything it does is reversible, and the cleanup commands are printed at the end.

## The point of running it

At the end you have a working identity called `james` in the group `developers` — and **nothing was created in Kubernetes**. There is no user object, nothing to `kubectl get`, nothing to delete. All that exists is a certificate signed by the cluster CA with a `CN` and an `O` in its Subject, which is the entire definition of a normal user.

Then:

```bash
kubectl --context=james@<cluster> auth whoami       # the username and groups the server sees
kubectl --context=james@<cluster> auth can-i --list
kubectl --context=james@<cluster> get pods          # Error from server (Forbidden)
```

**That 403 is the lesson.** Authentication succeeded — the API server knows exactly who you are. Authorization denied, because no Role or RoleBinding mentions `james` or `developers` yet. The two stages from chapter 05-01, visible in one command.

Roles and bindings are the next chapter; run this first and the 403 turns into a 200 without touching the certificate.

## Things worth pausing on

**Step 2 — the Subject is the identity.** `-subj "/CN=james/O=developers"` is the whole thing. `CN` becomes the username, `O` becomes a group, and repeating `O=` adds more groups.

**Step 4 — approval is the control.** Nothing stops you generating a CSR that says `CN=system:admin/O=system:masters`. What stops you is that approving it requires RBAC permission on the `certificatesigningrequests/approval` subresource. The request is free; the signature is not.

**`expirationSeconds: 86400`** is deliberate. Kubernetes **does not support certificate revocation** — an issued certificate is valid until it expires — so a short lifetime is the only built-in limit on a credential you hand out. This is the practical reason enterprises prefer short-lived OIDC tokens.

**`--embed-certs=true`** in step 6 inlines the certificate data rather than storing file paths, which is what makes the resulting kubeconfig portable to another machine.

## Reading any kubeconfig's identity

Not specific to this script — works on whatever context you are using right now:

```bash
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' \
  | base64 -d | openssl x509 -noout -subject -dates
```

On a fresh kubeadm or k3s cluster that prints `Subject: O = system:masters, CN = system:admin` — the group bound to `cluster-admin`, which is why the installer's kubeconfig can do anything.

If the command returns nothing, your kubeconfig authenticates some other way. Check for an `auth-provider` or `exec` block instead:

```bash
kubectl config view -o jsonpath='{.users[0].user}' | python -m json.tool
```

That is the OIDC/SSO shape — an `id-token` carrying the identity in its JWT claims rather than a certificate Subject.
