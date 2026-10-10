# Helm

Companion lab for [`05-21 Helm`](../../notes/05-kubernetes-deep-dive/21-helm.md). Full command reference: [`notes/commands/helm.md`](../../notes/commands/helm.md).

| File | What it is |
|---|---|
| [`values-dev.yaml`](values-dev.yaml) | A values override for the public `podinfo` chart — shows how `-f` changes a release without touching the chart |

## 1. Consume a chart: repository → chart → release

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo                         # CHART VERSION vs APP VERSION
helm show values podinfo/podinfo | head -30

helm install web podinfo/podinfo -f values-dev.yaml
helm list                                        # REVISION 1, STATUS deployed
kubectl get deploy,pods,svc                     # web-podinfo: "<release>-<chart>" from _helpers.tpl
kubectl get secrets -l owner=helm                # sh.helm.release.v1.web.v1

helm upgrade web podinfo/podinfo -f values-dev.yaml --set replicaCount=3   # --set beats -f
helm history web                                 # revision 2
helm rollback web 1                              # revision 3, with revision 1's content
kubectl get deploy web-podinfo -o jsonpath='{.spec.replicas}{"\n"}'        # 2 again
helm uninstall web
kubectl get secrets -l owner=helm                # gone: uninstall removed the history too
```

## 2. Author a chart: the lecture's flow

```bash
helm create flappy-app
tree -a flappy-app                               # -a shows .helmignore too
cd flappy-app
# Chart.yaml: set description, keep version 0.1.0, set appVersion to your app's version
# values.yaml: set image.repository (and image.tag, or rely on appVersion)
helm lint .
helm template . | grep image:                    # check the tag that will actually be used
helm package .                                   # flappy-app-0.1.0.tgz
helm install flappy-app flappy-app-0.1.0.tgz
helm list                                        # CHART flappy-app-0.1.0, APP VERSION = appVersion
kubectl port-forward svc/flappy-app 8080:80
helm uninstall flappy-app
```

## 3. The image-tag trap

```bash
helm create trap && cd trap
sed -i 's|repository: nginx|repository: busybox|' values.yaml   # change the image, leave tag: ""
helm template . | grep image:                    # image: "busybox:1.16.0" -- the appVersion, not latest
```
