# RBAC — identity

Companion script for [`05-02 RBAC part 1`](../../notes/05-kubernetes-deep-dive/02-rbac-identity-and-kubeconfig.md).

| File | What it does |
|---|---|
| [`create-user-certificate.sh`](create-user-certificate.sh) | Builds a second identity from scratch: private key → CSR → Kubernetes `CertificateSigningRequest` → admin approval → signed certificate → a new kubeconfig context |
| [`cluster-superhero.yaml`](cluster-superhero.yaml) | Rebuilds the built-in superuser from scratch — a ClusterRole with every verb on every resource, bound to a group that does not exist |
| [`pod-reader.yaml`](pod-reader.yaml) | The minimum viable grant, and the fix for the deliberate `403` above |

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

## Part 2 — turning the 403 into a 200

```bash
kubectl apply -f pod-reader.yaml
kubectl --context=james@<cluster> get pods      # now it works
```

**Nothing about the certificate changed.** Authentication was always succeeding; only the authorization stage's answer moved. That is the two-stage split from chapter 05-01 in two commands.

The manifest binds both the **User** `james` (the certificate's `CN`) and the **Group** `developers` (its `O`). Try each in turn:

```bash
kubectl auth can-i list pods --as=james                          # yes, via the User subject
kubectl auth can-i list pods --as=anyone --as-group=developers   # yes, via the Group subject
kubectl auth can-i delete pods --as=james                        # no — the role grants no delete
```

## The superhero demonstration

```bash
kubectl apply -f cluster-superhero.yaml
kubectl get clusterrolebindings -o wide | egrep 'NAME|^cluster-'

kubectl auth can-i '*' '*' --as-group="cluster-superheroes" --as="batman"       # yes
kubectl auth can-i '*' '*' --as-group="cluster-superheroes" --as="superman"     # yes
kubectl auth can-i '*' '*' --as-group="cluster-superheroes" --as="wonder-woman" # yes
kubectl auth can-i '*' '*' --as="batman"                                        # NO
```

Three usernames that exist nowhere, all granted everything — and the same username **without** the group granted nothing. **The binding names a group, and group membership arrives in the credential.** That is precisely how `system:admin` inherits `cluster-admin` through `system:masters` without appearing in any binding.

```bash
kubectl delete -f cluster-superhero.yaml -f pod-reader.yaml
```
