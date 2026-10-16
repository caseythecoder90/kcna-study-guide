# GitOps — commands

Companion to section 7: [`07-02 Argo CD`](../07-cloud-native-application-delivery/02-argo-cd.md). Runnable lab: [`examples/argocd/`](../../examples/argocd/).

## Argo CD: install (the course's way)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'   # lab only: plain HTTP
kubectl -n argocd rollout restart deployment/argocd-server
watch --difference kubectl get all -n argocd
kubectl -n argocd get svc                                         # argocd-server 80/443, repo-server 8081, redis 6379, dex 5556-5558
```

## Log in

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo   # user: admin
argocd admin initial-password -n argocd                           # same, via the CLI
kubectl -n argocd port-forward svc/argocd-server 8080:80
argocd login localhost:8080 --username admin --password <pw> --insecure
argocd account update-password
kubectl -n argocd delete secret argocd-initial-admin-secret       # once the password is changed
```

## Applications

```bash
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook \
  --dest-server https://kubernetes.default.svc --dest-namespace guestbook \
  --sync-policy automated --auto-prune --self-heal --sync-option CreateNamespace=true
argocd app list
argocd app get guestbook                                          # sync status, health status, resource tree
argocd app diff guestbook                                         # live vs Git
argocd app sync guestbook                                         # manual sync
argocd app history guestbook
argocd app rollback guestbook <id>                                # undone by the next auto-sync: revert in Git instead
argocd app set guestbook --self-heal                              # turn self-heal on
argocd app delete guestbook                                       # cascades to the app's resources

kubectl apply -f guestbook-application.yaml                       # declarative: the GitOps way
kubectl -n argocd get applications,applicationsets,appprojects
kubectl -n argocd patch application guestbook --type merge -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":false}}}}'
```

## Clusters and projects

```bash
argocd cluster add <kube-context>                                 # register another cluster (hub-and-spoke)
argocd cluster list
argocd proj list
```

## Watch self-healing

```bash
kubectl -n guestbook scale deploy guestbook-ui --replicas=4       # reverted by selfHeal
kubectl delete namespace guestbook                                # the course's demo: recreated from Git
```

## Argo Workflows (chapter [07-03](../07-cloud-native-application-delivery/03-argo-workflows-and-the-argo-family.md))

```bash
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v4.1.5/quick-start-minimal.yaml
argo submit -n argo --watch parallel-dag.yaml            # examples/argo-workflows/
argo list -n argo
argo get -n argo @latest
argo logs -n argo @latest
argo template list -n argo ; argo cron list -n argo
kubectl -n argo port-forward svc/argo-server 2746:2746   # UI (self-signed HTTPS)
```
