# Argo CD

Companion lab for [`07-02 Argo CD`](../../notes/07-cloud-native-application-delivery/02-argo-cd.md). Works on kind, k3s or any cluster.

| File | What it is |
|---|---|
| [`guestbook-application.yaml`](guestbook-application.yaml) | An `Application` for the public guestbook example, auto-synced with **prune** and **self-heal** |
| [`tenants-applicationset.yaml`](tenants-applicationset.yaml) | An `ApplicationSet` whose **list generator** creates one Application per tenant namespace |

## 1. Install (the lecture's commands)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'   # lab only
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd get pods -w                                                    # wait for all Running

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8080:80                         # http://localhost:8080, user admin
```

Optional CLI: `brew install argocd`, or download from the Argo CD GitHub releases. Then `argocd login localhost:8080 --username admin --insecure`.

## 2. Deploy declaratively and watch it heal

```bash
kubectl apply -f guestbook-application.yaml
kubectl -n argocd get applications                         # SYNC STATUS / HEALTH STATUS columns
kubectl -n guestbook get all

kubectl -n guestbook scale deploy guestbook-ui --replicas=4  # drift: back to 1 within seconds
kubectl -n guestbook get deploy guestbook-ui -w

kubectl delete namespace guestbook                         # the lecture's demo
kubectl get ns guestbook -w                                # Terminating ... then a new one is created
kubectl -n guestbook get all                               # everything is back
```

Now turn **self-heal off** (`kubectl -n argocd patch application guestbook --type merge -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":false}}}}'`) and scale again: the app goes **OutOfSync** and stays that way until you sync. That's the difference between `automated` and `selfHeal`.

## 3. One app, many tenants

```bash
kubectl apply -f tenants-applicationset.yaml
kubectl -n argocd get applications                         # guestbook-acme, guestbook-globex, guestbook-initech
kubectl get ns | grep tenant-
```

Add `- tenant: umbrella` to the list and apply: a fourth Application and namespace appear. Remove a line and that tenant's Application is deleted.

## 4. Clean up

```bash
kubectl -n argocd delete applicationset guestbook-tenants
kubectl -n argocd delete application guestbook
kubectl delete namespace argocd
```
