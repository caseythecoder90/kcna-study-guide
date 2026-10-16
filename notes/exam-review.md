# Exam review — the last two weeks

> The chapters teach, and [`exam-facts.md`](exam-facts.md) (≈1,000 facts) and [`cncf-projects.md`](cncf-projects.md) (≈140 projects) are the reference. This page is the **plan**: where the marks are, which pairs of things the exam loves to confuse, and how to turn practice-exam misses into points.

---

## 1. Where the marks are

60 questions, 90 minutes, pass above 75% (**45 correct**). About 90 seconds per question: a first pass at about one minute each leaves 30 minutes to revisit flagged ones.

| Domain | Weight | ≈ Questions | Read these chapters |
|---|---|---|---|
| **Kubernetes Fundamentals** | **44%** | **~26** | [04-01 architecture](04-kubernetes-fundamentals/01-container-orchestration-and-architecture.md) · [04-02 Pods](04-kubernetes-fundamentals/02-pods.md) · [04-04 namespaces](04-kubernetes-fundamentals/04-namespaces.md) · [04-05 Deployments](04-kubernetes-fundamentals/05-deployments-and-replicasets.md) · [04-06 DaemonSets](04-kubernetes-fundamentals/06-daemonsets.md) · [04-08 Services](04-kubernetes-fundamentals/08-services.md) · [04-09 Jobs](04-kubernetes-fundamentals/09-jobs-and-cronjobs.md) · [04-10 ConfigMaps](04-kubernetes-fundamentals/10-configmaps.md) · [04-11 Secrets](04-kubernetes-fundamentals/11-secrets.md) · [04-12 labels](04-kubernetes-fundamentals/12-labels-and-selectors.md) · [05-01 the API](05-kubernetes-deep-dive/01-kubernetes-api.md) · [05-05 scheduler](05-kubernetes-deep-dive/05-kube-scheduler.md) · [05-06 taints](05-kubernetes-deep-dive/06-taints-and-tolerations.md) · [05-07 affinity](05-kubernetes-deep-dive/07-affinity-and-anti-affinity.md) · [05-09 StatefulSets](05-kubernetes-deep-dive/09-statefulsets.md) · [section 3 containers](03-containers-with-docker/) |
| **Container Orchestration** | **28%** | **~17** | [02-07 open standards (OCI, CRI, CNI, CSI)](02-cloud-native-architecture/07-open-standards.md) · [05-02](05-kubernetes-deep-dive/02-rbac-identity-and-kubeconfig.md) to [05-04 RBAC](05-kubernetes-deep-dive/04-rbac-csr-pipeline-and-roles.md) · [05-08 storage](05-kubernetes-deep-dive/08-kubernetes-storage.md) · [05-10 NetworkPolicy](05-kubernetes-deep-dive/10-network-policies.md) · [05-11 Ingress](05-kubernetes-deep-dive/11-ingress.md) · [05-12 Gateway API](05-kubernetes-deep-dive/12-gateway-api.md) · [05-14](05-kubernetes-deep-dive/14-security-overview.md) to [05-16 security](05-kubernetes-deep-dive/16-pod-security-admission.md) · [05-17 quotas](05-kubernetes-deep-dive/17-resource-quotas.md) · [05-23 service mesh](05-kubernetes-deep-dive/23-service-meshes.md) · [04-03 troubleshooting](04-kubernetes-fundamentals/03-troubleshooting-pods.md) · [04-14](04-kubernetes-fundamentals/14-probes.md) / [05-20 probes](05-kubernetes-deep-dive/20-probes-and-the-kubelet.md) |
| **Cloud Native Application Delivery** | **16%** | **~10** | [07-01 GitOps](07-cloud-native-application-delivery/01-application-delivery-and-gitops.md) · [07-02 Argo CD](07-cloud-native-application-delivery/02-argo-cd.md) · [07-03 Argo Workflows](07-cloud-native-application-delivery/03-argo-workflows-and-the-argo-family.md) · [07-04 Flux](07-cloud-native-application-delivery/04-flux-and-the-gitops-toolkit.md) · [05-21 Helm](05-kubernetes-deep-dive/21-helm.md) · [05-22 Kustomize](05-kubernetes-deep-dive/22-kustomize.md) · [02-02 CI/CD](02-cloud-native-architecture/02-cloud-native-practices.md) · [04-05 rollouts](04-kubernetes-fundamentals/05-deployments-and-replicasets.md) |
| **Cloud Native Architecture** | **12%** | **~7** | [01-01 what is cloud native](01-cloud-native-introduction/01-what-is-cloud-native.md) · [02-01 microservices](02-cloud-native-architecture/01-monolithic-vs-microservices.md) · [02-03 autoscaling](02-cloud-native-architecture/03-autoscaling.md) · [02-04 serverless](02-cloud-native-architecture/04-serverless.md) · [02-05 CNCF governance](02-cloud-native-architecture/05-community-and-governance.md) · [02-06 personas](02-cloud-native-architecture/06-cloud-native-personas.md) · **observability**: [06-01](06-telemetry-and-observability/01-cloud-native-observability.md) · [06-02](06-telemetry-and-observability/02-prometheus-and-grafana.md) · [06-05 cost](06-telemetry-and-observability/05-cost-management.md) |

**Fundamentals is nearly half the exam.** If time is short, re-read section 4 and the scheduling and API chapters of section 5 before anything else.

---

## 2. The pairs the exam confuses on purpose

Most wrong answers on the KCNA are the **right answer to a neighbouring question**. Drill these until each line is instant.

| Pair / group | The one-line difference | Chapter |
|---|---|---|
| Container vs VM | Shared host **kernel** (namespaces + cgroups) vs a full guest OS on a hypervisor | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Docker vs containerd vs runc | Developer tool/engine vs **high-level CRI runtime** vs **low-level OCI runtime** that creates the container | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI vs CRI vs CNI vs CSI | **Image/runtime format** vs kubelet ↔ **runtime** API vs **networking** plugins vs **storage** plugins | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| Control plane components | **API server** (front door, only one that talks to etcd) · **etcd** (state) · **scheduler** (picks a node) · **controller manager** (reconcile loops) · **kubelet** (runs Pods on its node) · **kube-proxy** (Service rules) | [04-01](04-kubernetes-fundamentals/01-container-orchestration-and-architecture.md) |
| Pod vs Deployment vs ReplicaSet | Smallest deployable unit vs **rollouts + rollback** vs keeps N replicas (owned by the Deployment) | [04-05](04-kubernetes-fundamentals/05-deployments-and-replicasets.md) |
| Deployment vs StatefulSet vs DaemonSet vs Job | Stateless replicas vs **stable identity + per-Pod storage** vs **one per node** vs **run to completion** | [05-09](05-kubernetes-deep-dive/09-statefulsets.md), [04-06](04-kubernetes-fundamentals/06-daemonsets.md), [04-09](04-kubernetes-fundamentals/09-jobs-and-cronjobs.md) |
| ClusterIP vs NodePort vs LoadBalancer vs ExternalName vs headless | Internal VIP vs port **30000–32767** on every node vs cloud LB vs DNS CNAME vs **no VIP** (`clusterIP: None`, Pod IPs in DNS) | [04-08](04-kubernetes-fundamentals/08-services.md) |
| Ingress vs Gateway API vs NetworkPolicy | L7 HTTP routing (frozen) vs its **role-oriented successor** vs an **L3/L4 firewall** for Pods | [05-11](05-kubernetes-deep-dive/11-ingress.md), [05-12](05-kubernetes-deep-dive/12-gateway-api.md), [05-10](05-kubernetes-deep-dive/10-network-policies.md) |
| ConfigMap vs Secret | Non-sensitive config vs sensitive data, **base64-encoded, not encrypted** by default | [04-11](04-kubernetes-fundamentals/11-secrets.md) |
| Labels vs annotations | **Selectable** identifying metadata vs non-selectable notes for tools | [04-13](04-kubernetes-fundamentals/13-annotations.md) |
| Role vs ClusterRole; RoleBinding vs ClusterRoleBinding | **Namespaced** vs cluster-wide permissions; the binding decides where they apply | [05-03](05-kubernetes-deep-dive/03-rbac-clusterroles-and-bindings.md) |
| Authentication vs authorization vs admission | **Who are you** vs **may you** (RBAC) vs **should this object be changed or allowed** (webhooks, PSA) | [05-01](05-kubernetes-deep-dive/01-kubernetes-api.md) |
| nodeSelector vs node affinity vs taints/tolerations | Pod **attracted** to labelled nodes (simple vs expressive) vs node **repels** Pods that don't tolerate it | [05-06](05-kubernetes-deep-dive/06-taints-and-tolerations.md), [05-07](05-kubernetes-deep-dive/07-affinity-and-anti-affinity.md) |
| ResourceQuota vs LimitRange | **Namespace total** vs **per-container** defaults and bounds | [05-17](05-kubernetes-deep-dive/17-resource-quotas.md) |
| Requests vs limits | **Scheduling** reservation vs **runtime cap** (CPU throttled, memory OOMKilled) | [05-17](05-kubernetes-deep-dive/17-resource-quotas.md) |
| Pod Security Standards vs Pod Security Admission | The **levels** (privileged, baseline, restricted) vs the **built-in admission controller** enforcing them per namespace | [05-16](05-kubernetes-deep-dive/16-pod-security-admission.md) |
| Liveness vs readiness vs startup probe | Fail → **restart** vs fail → **removed from Service endpoints** vs holds the other two off during startup | [04-14](04-kubernetes-fundamentals/14-probes.md) |
| PV vs PVC vs StorageClass | The storage vs **the request** for it vs **dynamic provisioning** template | [05-08](05-kubernetes-deep-dive/08-kubernetes-storage.md) |
| HPA vs VPA vs Cluster Autoscaler vs KEDA | More **Pods** vs bigger **requests** vs more **nodes** vs event-driven, **scale to zero** | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Helm vs Kustomize | **Templates + values**, packages and releases vs **patches + overlays** on plain YAML, built into kubectl | [05-22](05-kubernetes-deep-dive/22-kustomize.md) |
| Push CI/CD vs GitOps | Pipeline applies with cluster credentials vs **in-cluster agent pulls** from Git and **continuously reconciles** | [07-01](07-cloud-native-application-delivery/01-application-delivery-and-gitops.md) |
| Argo CD vs Argo Workflows vs Argo Rollouts vs Argo Events | **GitOps CD** vs **parallel jobs / pipelines** vs **canary and blue-green** vs **event triggers** | [07-03](07-cloud-native-application-delivery/03-argo-workflows-and-the-argo-family.md) |
| Argo CD vs Flux | Centralized app + **UI**, manual sync by default vs **GitOps Toolkit** controllers, per cluster, automatic sync | [07-04](07-cloud-native-application-delivery/04-flux-and-the-gitops-toolkit.md) |
| Logs vs metrics vs traces (vs alerts) | What happened vs how much/how often vs where a request spent its time; **alerts are not a pillar** | [06-01](06-telemetry-and-observability/01-cloud-native-observability.md) |
| Gauge vs counter vs histogram vs summary | Up and down vs **only up** vs server-side **buckets** vs client-side quantiles | [06-02](06-telemetry-and-observability/02-prometheus-and-grafana.md) |
| metrics-server vs kube-state-metrics vs node-exporter | **Current CPU/memory** for `kubectl top` and the HPA vs **object state** from the API vs **node hardware/OS** | [06-02](06-telemetry-and-observability/02-prometheus-and-grafana.md) |
| Prometheus vs Grafana | **Collects and stores** (TSDB, PromQL, pull) vs **visualizes** (stores nothing) | [06-04](06-telemetry-and-observability/04-hands-on-with-grafana.md) |
| Data plane vs control plane (service mesh) | **Proxies carrying the traffic** (Envoy sidecars) vs the **brain configuring them** (istiod) | [05-23](05-kubernetes-deep-dive/23-service-meshes.md) |
| SLI vs SLO vs SLA | The **measurement** vs the internal **target** vs the **customer contract** | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| On-Demand vs Reserved vs Spot | No commitment, full price vs **1–3 year commitment, ≤72% off** vs **spare capacity, ≤90% off, can be reclaimed** | [06-05](06-telemetry-and-observability/05-cost-management.md) |
| CNCF Sandbox vs Incubating vs Graduated | Early vs growing adoption vs **mature, widely adopted, audited** | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |

---

## 3. Ports and numbers worth one last look

| What | Value |
|---|---|
| kube-apiserver | **6443** |
| etcd client / peer | **2379 / 2380** |
| kubelet API | **10250** |
| kube-scheduler / kube-controller-manager (secure metrics) | 10259 / 10257 |
| NodePort range | **30000–32767** |
| CoreDNS | 53 (metrics 9153) |
| Prometheus · Alertmanager · Pushgateway · node-exporter · Grafana | **9090 · 9093 · 9091 · 9100 · 3000** |
| Argo CD server · Argo Workflows UI | 80/443 · 2746 |
| Prometheus default retention · scrape | **15 days** · interval set per job |
| Node unreachable → Pod eviction | ≈ 50 s to `Unknown` + **300 s** default toleration |
| Argo CD Git polling | **≤ 3 min** (120 s + jitter) |
| Spot interruption notice (AWS) | **2 minutes** |
| Kubernetes open-sourced · CNCF founded | **2014** · **2015** |
| Prometheus | 2nd CNCF project (**2016**), 2nd to graduate (**2018**) |

---

## 4. A two-week plan

| Days | Do |
|---|---|
| 1–3 | **Section 4 end to end** (Fundamentals = 44%), then [05-01](05-kubernetes-deep-dive/01-kubernetes-api.md), [05-05](05-kubernetes-deep-dive/05-kube-scheduler.md) to [05-07](05-kubernetes-deep-dive/07-affinity-and-anti-affinity.md). Read each chapter's **Exam angle** twice |
| 4 | **Full practice exam #1**, timed. Don't look anything up during it |
| 5–6 | Fix the misses (below). Then section 5 security, networking and storage |
| 7 | Sections 6 and 7 (observability, GitOps) plus [`cncf-projects.md`](cncf-projects.md): cover the "What it does" column and name the project |
| 8 | **Practice exam #2** |
| 9–10 | Fix the misses. Sections 1–3 (definitions, CNCF, personas, standards, containers) |
| 11 | **Practice exam #3**. You're ready when you score **≥ 85%** consistently (the margin over 75% absorbs the real exam's surprises) |
| 12–13 | Section 2 above (the pairs) and every **Exam angle** section, nothing else |
| 14 | Light review of section 3 above. Sleep |

### Turning a missed question into points

1. Find the topic in [`exam-facts.md`](exam-facts.md) (Ctrl+F the key term) and follow its chapter link.
2. Decide **why** you missed it: didn't know the fact, confused two neighbours (section 2 above), or misread the question ("which is **NOT**...").
3. If the fact isn't in the notes, **add it** to `exam-facts.md` under its section. The recall sheet is meant to grow from practice exams too.
4. If two things keep getting confused, add the pair to section 2 above.

### On exam day

- **Read the last line of the question first.** "Which is NOT", "which TWO", "the BEST" change the answer.
- **Eliminate first.** Two options are usually clearly wrong. Of the remaining two, the exam wants the **most specific, official** term (*kube-scheduler*, not "the control plane"; *PodDisruptionBudget*, not "a policy").
- **Flag and move on** after about 90 seconds. Unanswered questions score zero, and there's no penalty for guessing.
- **Current over historical:** if an option is deprecated (dockershim, PodSecurityPolicy, SMI, Ingress for new features, Spot "bidding"), it's usually the distractor, unless the question asks about history.
