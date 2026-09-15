# CNCF projects and standards — cheat sheet

> One row per project, tool, or specification the course mentions. Category and maturity are what the exam asks about most ("which of these is a CNCF graduated project?", "which project provides X?"). Updated in the same PR as every chapter; the course's own *Product Summary Cheat Sheet* (section 9) is folded in here at the end.
>
> Maturity levels, lowest to highest: **Sandbox → Incubating → Graduated**. "Not CNCF" marks tools that are widely used in the ecosystem but are not CNCF projects (Docker, Terraform, Ansible, ...). Check current status at https://landscape.cncf.io/ before the exam — projects move.

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

## Organizations (not projects, but they appear in questions)

| Name | What it is | Introduced in |
|---|---|---|
| **CNCF** — Cloud Native Computing Foundation | Vendor-neutral home for cloud native open source projects; part of the Linux Foundation; founded 2015 around Kubernetes | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| **Linux Foundation** | Nonprofit parent of the CNCF (and of many other open source foundations) | [01-01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
