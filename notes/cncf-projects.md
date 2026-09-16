# CNCF projects and standards — cheat sheet

> One row per project, tool, or specification the course mentions. Category and maturity are what the exam asks about most ("which of these is a CNCF graduated project?", "which project provides X?"). Updated in the same PR as every chapter; the course's own *Product Summary Cheat Sheet* (section 9) is folded in here at the end.
>
> Maturity levels, lowest to highest: **Sandbox → Incubating → Graduated** (plus **Archived**); the TOC moves projects between them by 2/3 vote — see [02-05](02-cloud-native-architecture/05-community-and-governance.md). "Not CNCF" marks tools that are widely used in the ecosystem but are not CNCF projects (Docker, Terraform, Ansible, ...). Check current status at https://landscape.cncf.io/ before the exam — projects move.

| Project / standard | Category | CNCF maturity | What it does | Introduced in |
|---|---|---|---|---|
| **Kubernetes** | Orchestration | Graduated | Container orchestration platform. Open-sourced by Google in 2014, donated to the CNCF in 2015 as its first project | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| **Terraform** | Infrastructure as code | Not CNCF (HashiCorp / IBM) | Declarative provisioning of cloud infrastructure through provider APIs | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| **Ansible** | Configuration management / automation | Not CNCF (Red Hat) | Agentless automation of configuration and provisioning, also usable for cloud automation via provider APIs | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| **etcd** | Key/value store / coordination | Graduated | Distributed, reliable key/value store using Raft consensus; the datastore behind the Kubernetes control plane | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| **NGINX** | Web server / reverse proxy | Not CNCF (F5) | High-performance web server and reverse proxy; basis of the widely used NGINX Ingress controller | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| **Apache HTTP Server** | Web server | Not CNCF (Apache Software Foundation) | The classic open source web server, typical front for PHP/Java monoliths | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| **ODBC** (standard) | Database connectivity API | Not CNCF (standard, not a project) | Open Database Connectivity — the driver interface a monolith's data layer is classically bound to | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| **Raft** (algorithm) | Consensus algorithm | Not CNCF (algorithm, not a project) | Leader-based consensus used by etcd to keep replicas consistent | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| **Knative** | Serverless / application layer | Graduated (Sep 2025; incubating Mar 2022) | Serverless application layer on Kubernetes: HTTP-triggered autoscaling containers that can **scale to zero**, plus eventing | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **CoreDNS** | Service discovery / DNS | Graduated | The cluster DNS server that gives every Service a `<svc>.<ns>.svc.cluster.local` name | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **Istio** | Service mesh | Graduated | Service mesh providing mTLS, traffic management and observability between services via Envoy sidecars/ambient mode | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **Linkerd** | Service mesh | Graduated | Lightweight service mesh providing mTLS and observability with its own micro-proxy | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **SPIFFE / SPIRE** | Workload identity | Graduated | Standard (SPIFFE) and implementation (SPIRE) for issuing cryptographic workload identities — the identity foundation for zero trust / mTLS | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **Git** | Version control | Not CNCF | The commit that triggers every CI/CD pipeline; the source of truth in GitOps (Section 7) | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| **KEDA** | Autoscaling (event-driven) | Graduated (Aug 2023) | Kubernetes Event-Driven Autoscaling: ScaledObject + external triggers (queues, Kafka, Prometheus, cron); scales 0 → 1 itself and drives an HPA for 1 → n; scale to zero | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| **Cluster Autoscaler** | Autoscaling (nodes) | Kubernetes SIG Autoscaling (kubernetes/autoscaler), not a separate CNCF project | Adds nodes when Pods can't be scheduled for lack of resources; removes underutilized nodes | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| **VerticalPodAutoscaler (VPA)** | Autoscaling (Pod resources) | Kubernetes SIG Autoscaling add-on | Adjusts Pod CPU/memory requests and limits from observed usage; not shipped with Kubernetes by default | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| **metrics-server** | Metrics | Kubernetes SIG Instrumentation add-on | Cluster-wide aggregator of CPU/memory usage that HPA and VPA read; also backs `kubectl top` | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| **VMware ESXi** | Hypervisor | Not CNCF (Broadcom) | Bare-metal hypervisor; the lecture's example of vertical scaling by granting a VM more of its host | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| **CloudEvents** | Serverless / eventing specification | Graduated (Jan 2024) | Specification for describing event data in a common way; SDKs in many languages; bindings for AMQP, HTTP, Kafka, MQTT, NATS, WebSockets; used by Knative Eventing | [02-04](02-cloud-native-architecture/04-serverless.md) |
| **OpenFaaS** | Serverless / FaaS on Kubernetes | Not CNCF (OpenFaaS Ltd; on the landscape) | Deploy functions as OCI images to any Kubernetes cluster; scales to zero; Community Edition and Pro | [02-04](02-cloud-native-architecture/04-serverless.md) |
| **AWS Lambda** | FaaS (public cloud) | Not CNCF (AWS) | The reference Function-as-a-Service: upload a .zip or container image, per-event execution, per-ms billing, provisioned concurrency for cold starts | [02-04](02-cloud-native-architecture/04-serverless.md) |
| **Kourier / Contour** | Ingress (Knative networking layers) | Contour: Incubating (Jul 2020) · Kourier: part of Knative | Envoy-based ingress layers Knative Serving can route through (Istio is the third option) | [02-04](02-cloud-native-architecture/04-serverless.md) |
| **Prometheus** | Observability / monitoring | Graduated (Aug 2018; joined May 2016 — the 2nd CNCF project, 2nd to graduate) | Monitoring system and time-series database; pull-based metrics scraping, PromQL, alerting (Section 6) | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| **Envoy** | Service proxy | Graduated (Nov 2018; joined Sep 2017) | High-performance edge/middle/service proxy created at Lyft; the data plane under Istio and many ingress controllers | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| **OpenCost** | Cost management (FinOps) | Incubating (Oct 2024; joined Jun 2022) | Real-time Kubernetes cost allocation and monitoring — the FinOps engineer's view of the cluster | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| **Backstage** | Developer portal / platform engineering | Incubating (Mar 2022; joined Sep 2020) | Open framework for building internal developer portals, created at Spotify | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| **Kubeflow** | AI / ML platform | Graduated (Jul 2026; incubating Jul 2023) | Toolkit for building AI platforms on Kubernetes — pipelines, training, notebooks; the ML engineer's platform | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| **Terraform** | Infrastructure as code | Not CNCF (HashiCorp / IBM) — see [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) | Named again here as the CloudOps engineer's core tool for provisioning across clouds | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |

## Organizations (not projects, but they appear in questions)

| Name | What it is | Introduced in |
|---|---|---|
| **CNCF** — Cloud Native Computing Foundation | Vendor-neutral home for cloud native open source projects; part of the Linux Foundation; founded 2015 around Kubernetes | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| **Linux Foundation** | Nonprofit parent of the CNCF (and of many other open source foundations) | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
