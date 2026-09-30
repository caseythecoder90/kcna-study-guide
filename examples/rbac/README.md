# RBAC — identity

Companion script for [`05-02 RBAC part 1`](../../notes/05-kubernetes-deep-dive/02-rbac-identity-and-kubeconfig.md).

| File | What it does |
|---|---|
| [`create-user-certificate.sh`](create-user-certificate.sh) | Builds a second identity from scratch: private key → CSR → Kubernetes `CertificateSigningRequest` → admin approval → signed certificate → a new kubeconfig context |
| [`cluster-superhero.yaml`](cluster-superhero.yaml) | Rebuilds the built-in superuser from scratch — a ClusterRole with every verb on every resource, bound to a group that does not exist |
| [`pod-reader.yaml`](pod-reader.yaml) | The minimum viable grant, and the fix for the deliberate `403` above |
| [`scoped-roles.yaml`](scoped-roles.yaml) | The two roles that are **not** "everything": a read-only ClusterRole, and a namespaced Role + RoleBinding |
| [`serviceaccount-demo.yaml`](serviceaccount-demo.yaml) | The third subject kind: the `default` ServiceAccount a Pod gets for free, a custom one that was actually granted something, and one with no token at all |

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

## Part 3 — the two dials

```bash
kubectl apply -f scoped-roles.yaml
```

**Dial one: the verb list.** `cluster-watcher` differs from `cluster-superhero` by exactly one field — the verbs. The resource is still `*`.

```bash
kubectl auth can-i '*' '*'     --as-group=cluster-watchers --as=uatu   # NO
kubectl auth can-i list pods   --as-group=cluster-watchers --as=uatu   # yes
kubectl auth can-i delete pods --as-group=cluster-watchers --as=uatu   # no
kubectl auth can-i --list      --as-group=cluster-watchers --as=uatu
```

That first `no` is not a bug. **`'*'` is a literal verb being asked about**, and the role grants only `list`, `get` and `watch` — so `*` is not in the set. Only a genuine superuser answers yes to `can-i '*' '*'`. For anything narrower, ask a specific question or use `--list`.

**Dial two: the binding kind.** `gryffindor-admin` grants every verb on every resource — inside one namespace.

```bash
kubectl auth can-i '*' '*' --as-group=gryffindor-admins --as=harry
# no

kubectl -n gryffindor auth can-i '*' '*' --as-group=gryffindor-admins --as=harry
# yes
```

**Identical user, identical group, identical role. Only `-n` changed.** Without a namespace the question is cluster-wide, and this identity has no cluster-wide permissions at all.

```bash
kubectl delete -f scoped-roles.yaml
```

## Further study — ServiceAccounts

```bash
kubectl apply -f serviceaccount-demo.yaml
```

Three Pods, one image, one command. The only difference is which identity each one carries.

```bash
# The Pod that said nothing about identity
kubectl get pod robot-default -o jsonpath='{.spec.serviceAccountName}'   # default

kubectl exec -it robot-default -- sh -c '
  SA=/var/run/secrets/kubernetes.io/serviceaccount
  curl -s --cacert $SA/ca.crt -H "Authorization: Bearer $(cat $SA/token)"     https://kubernetes.default.svc/api/v1/namespaces/default/pods | head -5'
```

```
"message": "pods is forbidden: User \"system:serviceaccount:default:default\" cannot
            list resource \"pods\" in API group \"\" in the namespace \"default\""
```

**Authentication succeeded.** The API server names the identity exactly — `system:serviceaccount:default:default`, the `default` ServiceAccount of the Pod's own namespace, assigned automatically because the spec never mentioned one. Authorization denied, because that account is bound to nothing.

The same command in `robot-granted` returns a Pod list. Nothing about the image, the command or the network changed — only the RoleBinding.

```bash
kubectl exec -it robot-no-token -- ls /var/run/secrets/kubernetes.io/serviceaccount
# No such file or directory
```

`automountServiceAccountToken: false` removes the credential altogether. A Pod that never calls the API server should not be carrying one.

Impersonate the accounts to see the difference without a Pod at all:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:default:build-robot   # yes
kubectl auth can-i list pods --as=system:serviceaccount:default:default       # no
kubectl auth can-i --list    --as=system:serviceaccount:default:default
```

That last one is worth reading: the `default` ServiceAccount's entire permission set is the API discovery endpoints every authenticated principal gets. **That is the least-privilege default, and the reason most Pods need no ServiceAccount configuration at all.**

```bash
kubectl delete -f serviceaccount-demo.yaml
```
