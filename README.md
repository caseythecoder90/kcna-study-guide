# KCNA Study Guide

Exam-focused notes for the **Kubernetes and Cloud Native Associate (KCNA)** exam, built while working through James Spurin's Udemy course *KCNA: Kubernetes and Cloud Native Associate* and expanded with the definitions, comparisons, and context that make each fact stick.

The KCNA is a multiple-choice exam, so these notes optimize for recall: canonical definitions, "which component/project does X", dates, defaults, and comparison tables. Every chapter ends with an *Exam angle* section describing what a question on that topic looks like.

This is the second of five certifications on the road to CNCF [Kubestronaut](https://www.cncf.io/training/kubestronaut/) status. The first, CKAD, has its own repo: [ckad-exam-prep](https://github.com/caseythecoder90/ckad-exam-prep).

## Who this is for

- Anyone preparing for the KCNA who wants dense, skimmable notes plus recall sheets to drill from.
- Engineers new to the cloud native ecosystem who want a structured map of what the CNCF projects are and how they fit together.
- People collecting the Kubestronaut set who need the KCNA out of the way efficiently.

You do not need to read it front to back. Jump to a section, or drill the recall sheets the week before the exam. **Starting your final review? Begin with [`notes/exam-review.md`](notes/exam-review.md):** domain weights mapped to chapters, the pairs the exam confuses on purpose, the ports, and a two-week plan around practice exams.

**By the numbers:** all 7 course sections · 60 chapters, each ending in an *Exam angle* · 154 original diagrams · about 950 facts in the recall sheet · about 140 projects in the project cheat sheet · 39 runnable labs.

## Repository layout

```
kcna-study-guide/
├── README.md
├── notes/                                   # the study notes, one folder per course section
│   ├── 01-cloud-native-introduction/        #   each with its own diagrams/ (PlantUML → SVG)
│   ├── 02-cloud-native-architecture/
│   ├── 03-containers-with-docker/
│   ├── 04-kubernetes-fundamentals/
│   ├── 05-kubernetes-deep-dive/
│   ├── 06-telemetry-and-observability/
│   ├── 07-cloud-native-application-delivery/
│   ├── exam-review.md                       # START HERE for final review: domain map, confusable pairs, plan
│   ├── exam-facts.md                        # recall sheet: dates, versions, ports, defaults, personas
│   ├── cncf-projects.md                     # project cheat sheet: name, category, maturity, purpose
│   ├── commands/                            # per-topic command references from the hands-on lectures
│   ├── commands.md                          # global single-file command reference (Ctrl+F)
│   └── NOTES-WORKFLOW.md                    # how these notes are authored
├── tools/diagrams/                          # shared PlantUML theme + render script for every diagram
├── examples/                                # runnable manifests / Dockerfiles / Helm values from the labs
└── extras/                                  # beyond the exam: e.g. a Keycloak contributor starter guide
```

## Contents

| Section | Covers | Status |
|---|---|---|
| [01 · Cloud Native Introduction](notes/01-cloud-native-introduction/) | What cloud native is (and isn't), the CNCF, the four philosophies, how to tell if an app is cloud native | Complete |
| [02 · Cloud Native Architecture](notes/02-cloud-native-architecture/) | Monolith vs microservices; characteristics and pillars; self-healing, automation, CI/CD, secure by default, serverless, service discovery; autoscaling; serverless; community and governance; personas; open standards (OCI, CRI, CNI, CSI, SMI) | Complete |
| [03 · Containers with Docker](notes/03-containers-with-docker/) | Container history, namespaces, cgroups, shared kernel vs VMs; Docker Desktop; images, tags, layers, OverlayFS, digests; running containers and the full Docker command reference; ports, networks, volumes; building images (Dockerfile, multi-stage, non-root, buildx, registries) | Complete |
| [04 · Kubernetes Fundamentals](notes/04-kubernetes-fundamentals/) | Orchestrators and the market; kubeadm architecture — runc, containerd, kubelet, static pods, etcd, API server, scheduler, controller managers, kube-proxy, CoreDNS, HA; Pods as the smallest deployable unit — shared network namespace, one Pod IP, sidecars and init containers; kubectl from `run` to `explain`, imperative vs declarative; troubleshooting — phases vs the STATUS column, `describe`, events, logs and exec; namespaces — the four defaults, namespaced vs cluster-scoped, ResourceQuota vs LimitRange, RBAC scoping and kubeconfig contexts; Deployments and ReplicaSets — the ownership chain, pod-template-hash, rolling updates, revisions and rollback; DaemonSets — node coverage versus replica count, and the taints that decide which nodes are eligible; `kubectl set image` and `kubectl patch` — strategic merge vs JSON merge patch vs JSON Patch; Services — the four types, endpoints and EndpointSlices, headless Services and cluster DNS; Jobs and CronJobs — run-to-completion workloads, completions versus parallelism, cron schedules and cascading deletion; ConfigMaps — creation sources, consumption methods and update behaviour; Secrets — encoded not encrypted, the built-in types, TLS Secrets and what actually protects them; labels and selectors — the mechanism wiring Services, controllers, policies and scheduling together; annotations — the non-selectable counterpart and the signalling channel for Ingress controllers, cert-manager and service meshes; startup, liveness and readiness probes — how they gate each other and what each failure does | Complete |
| [05 · Kubernetes Deep Dive](notes/05-kubernetes-deep-dive/) | The Kubernetes API — REST paths and API groups, the authentication/authorization/admission stages, `--authorization-mode`, OpenAPI, CRDs, and API versioning and deprecation; RBAC — kubeconfig anatomy and multi-cluster customisation, certificates and the CN/O identity mapping, users versus ServiceAccounts, OIDC, ClusterRoles and ClusterRoleBindings, the CSR-to-kubeconfig pipeline, namespaced Roles and ServiceAccounts; the kube-scheduler — filtering, scoring and binding, custom schedulers, `nodeName` and `nodeSelector`; taints and tolerations; node affinity, inter-pod affinity and anti-affinity, `topologyKey` and topology spread constraints; storage — ephemeral vs persistent, StorageClass/PV/PVC, reclaim policies, Rook and Ceph; StatefulSets — sticky identity, headless Services, ordering and partitioned updates; NetworkPolicies — isolation, additive allow rules, default-deny, and NetworkPolicy versus the Ingress resource; Ingress — controllers and IngressClass, pathType, TLS termination and redirects; Gateway API — GatewayClass, Gateway and HTTPRoute, roles, redirects, weighted routing and release patterns; PodDisruptionBudgets with cordon and drain; security — the four layers, Pod Security Standards and Admission, runtime hardening, OIDC, security tooling and the 4C's; security contexts and privilege escalation; Pod Security Admission modes and levels; ResourceQuotas with CPU and memory units; node failure — NotReady vs Unknown, taint-based eviction and Pods stuck Terminating; garbage collection — owner references and cascading deletion; how the kubelet runs probes, with Spring Boot Actuator liveness/readiness endpoints; Helm — charts, repositories, Artifact Hub, releases, the chart files and Semantic Versioning; Kustomize — base and overlays, and Kustomize versus Helm; service meshes — data plane and control plane, sidecar versus per-node proxies, mTLS, Envoy and xDS, Istio, Linkerd and SMI | Complete |
| [06 · Telemetry and Observability](notes/06-telemetry-and-observability/) | Observability and telemetry — the three pillars (logs, metrics, traces) and why alerts are not one; gauges, counters, meters and histograms; traces and spans; `kubectl top` and the Metrics Server; OpenTracing and OpenTelemetry at the application layer; Prometheus — data model, PromQL, pull vs push, the TSDB, metric types, kube-state-metrics and node-exporter, the Prometheus Adapter and the HPA; Grafana; hands on with kube-prometheus-stack — the operator and its CRDs, the components, the Prometheus UI and PromQL; hands on with Grafana — data sources, dashboards, panels, variables, alerting and dashboards as code; cost management — FinOps, On-Demand vs Reserved vs Spot (how Spot really works), right sizing, cloud anomaly detection, Kubecost and OpenCost | Complete |
| [07 · Cloud Native Application Delivery](notes/07-cloud-native-application-delivery/) | Application delivery and GitOps — fast, scalable, resilient delivery, the four OpenGitOps principles, push vs pull deployment, drift and GitOps self-healing; Argo CD — architecture, Application and AppProject, sync vs health status, automated sync, self-heal and prune, the hands-on install, ApplicationSet; Argo Workflows and the Argo family — Workflows, Rollouts, Events; Flux and the GitOps Toolkit — source, kustomize, helm and notification controllers, bootstrap, and Argo CD versus Flux | Complete |

Course sections 8 (quiz summaries), 9 (product summary cheat sheet) and 10 (credits) have no folder of their own. Their content lives in the recall sheets.

Where the course slides were thin, outdated or wrong, the chapters say so and give the accurate version. Examples: Spot instances no longer use bidding; "meter" isn't a Prometheus metric type; the Prometheus Adapter exposes Prometheus metrics *to* Kubernetes; "Argo CD Workflows" is really Argo Workflows; SMI is archived.

## How to use it

1. **Learn a topic** — read its chapter in `notes/<section>/`. Definitions come first, then the mechanics, then an *Exam angle* section with the distractors to watch for.
2. **Plan the final review** — [`notes/exam-review.md`](notes/exam-review.md): which chapters carry the most marks, the confusable pairs, the ports, and how to turn practice-exam misses into points.
3. **Drill the facts** — [`notes/exam-facts.md`](notes/exam-facts.md) is one line per fact the exam can ask about. [`notes/cncf-projects.md`](notes/cncf-projects.md) maps every project the course mentions to its category, maturity and purpose.
4. **Run the labs** — the course is hands-on even though the exam is not. [`notes/commands.md`](notes/commands.md) collects the Docker, kubectl, Helm, Prometheus, Argo CD and Flux commands from the lectures; [`examples/`](examples/) holds the manifests.
5. **Cross-reference the official sources** — each chapter links the canonical kubernetes.io, cncf.io, or project documentation it draws from.

## About the KCNA exam

The KCNA is an online, proctored, **multiple-choice** exam: 60 questions in 90 minutes, passing score above 75%, certification valid for 2 years. Unlike the CKA/CKAD/CKS there is no live cluster and no terminal.

Current curriculum domains and weights:

| Domain | Weight | Topics |
|---|---|---|
| Kubernetes Fundamentals | 44% | Kubernetes Core Concepts, Administration, Scheduling, Containerization |
| Container Orchestration | 28% | Networking, Security, Troubleshooting, Storage |
| Cloud Native Application Delivery | 16% | Application Delivery, Debugging |
| Cloud Native Architecture | 12% | Observability, Cloud Native Ecosystem and Principles, Cloud Native Community and Collaboration |

Note: the course sections were built against the earlier five-domain curriculum (which had Observability as its own 8% domain). The content still maps cleanly; observability topics now sit inside *Cloud Native Architecture*.

Always confirm the current version, duration, and passing score on the official pages:

- KCNA curriculum: https://github.com/cncf/curriculum
- Exam page & candidate handbook: https://training.linuxfoundation.org/certification/kubernetes-cloud-native-associate/
- Kubestronaut program: https://www.cncf.io/training/kubestronaut/

## Status

**Complete.** All seven course sections are written, with recall sheets, command references and labs in sync. What's left is exam practice:

- **Practice exams.** Take them timed, then use the miss-handling loop in [`exam-review.md`](notes/exam-review.md). Facts the notes don't have yet get added to `exam-facts.md`, so the recall sheet keeps growing from real questions.
- **Re-check current status before the exam.** CNCF maturity levels and project versions move. [landscape.cncf.io](https://landscape.cncf.io/) is the source of truth.

## Extras

Not exam material, but grown out of it: [`extras/keycloak-starter-guide.md`](extras/keycloak-starter-guide.md) is a step-by-step path into contributing to Keycloak (CNCF incubating, Java/Quarkus) — run it, learn the architecture, build from source, trace requests with a debugger, write a test the project's way, land a first PR.

[`extras/vintage-mac-collecting.md`](extras/vintage-mac-collecting.md) is entirely off-topic: which old Macs are worth buying for a shelf, where to find them, and the maintenance that keeps a 30-year-old machine alive.

## Attribution & license

Notes were built while working through James Spurin's KCNA course and expanded with additional depth from the official CNCF and Kubernetes documentation. They are original write-ups intended for study and sharing; no course material is reproduced. Every diagram is an original PlantUML drawing (source `.puml` committed next to the rendered `.svg`), not a course slide.

This repository is dual-licensed (see [`LICENSE`](LICENSE)):

- **Notes & documentation** (`notes/`, diagrams, this README) — [CC BY 4.0](LICENSE-CC-BY-4.0). Reuse and adapt freely, including commercially, with attribution.
- **Code** (`examples/`, scripts, manifests, Dockerfiles) — [MIT](LICENSE-MIT).
