# Exam facts — recall sheet

> One line per fact the KCNA can ask about: dates, version thresholds, ports, defaults, personas, acronyms, "X was the first Y". Grouped by the course section that introduced the fact. Updated in the same PR as every chapter.
>
> Drill this file in the last week. If a line makes you pause, the chapter link tells you where to reread.

## The exam itself

| Fact | Value |
|---|---|
| Format | Multiple choice, online proctored (PSI) |
| Questions / time | 60 questions in 90 minutes |
| Passing score | Above 75% |
| Validity | 2 years |
| Domains and weights | Kubernetes Fundamentals 44% · Container Orchestration 28% · Cloud Native Application Delivery 16% · Cloud Native Architecture 12% |
| Kubestronaut set | KCNA + KCSA + CKA + CKAD + CKS, all active at the same time |

## 01 · Cloud Native Introduction

| Fact | Value | Chapter |
|---|---|---|
| Kubernetes open-sourced | **2014**, by **Google** | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Kubernetes donated to the CNCF | **2015** — the **first ever CNCF project** | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| CNCF parent organization | The **Linux Foundation** (CNCF is a sub-foundation of it) | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| CNCF Cloud Native Definition — versions | **v1.0** (2018, still shown on cncf.io; what the course and most questions use) and **v1.1** (approved 2024-02-26, in the cncf/toc repo) | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Definition v1.0 — example technologies | Containers, service meshes, microservices, immutable infrastructure, declarative APIs | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Definition v1.0 — system properties | Loosely coupled systems that are **resilient, manageable, observable**; robust automation → high-impact changes frequently and predictably with minimal toil | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Definition v1.1 — additions | Technologies add **serverless, multi-tenancy** (list is non-exhaustive); properties add **secure, sustainable** | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Cloud native personas named in the intro | DevOps, SRE, FinOps | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| The four cloud native philosophies (course framing) | Architecture, Personas, Community and Governance, Open Standards | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| "Is it cloud native?" — the four tests | Automated setup/delivery · designed for resilience · autoscales on workload · secure by default | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |
| Containers vs cloud native | Containers are a building block; **containers != cloud native** | [01](01-cloud-native-introduction/01-what-is-cloud-native.md) |

## 02 · Cloud Native Architecture

| Fact | Value | Chapter |
|---|---|---|
| Four goals of cloud native architecture (course framing) | **Application availability, cost management, efficiency, reliability** | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Monolithic application | All functionality in a **single deployable unit**; simplest to start, hard to maintain and scale as it grows | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Tightly coupled architecture | Components are interdependent — **a change in one component will likely impact other components**; needs coordinated rollouts | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Classic monolith layers | User Interface → Business Logic → Data Interface → Database | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| What the monolith is bound to | Runtime (PHP / Java) + web server (Apache HTTP Server / NGINX); database via an **ODBC** (Open Database Connectivity) driver | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Shared-host dependency conflict | Apps installed directly on the OS share one filesystem (`/usr/*`, `/etc/*`) and therefore **one copy of each library**; app2 needs Library XYZ v1.0, app3 needs v2.0 → neither can change independently. This is the host-level problem **containers** solve | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Microservices architecture | Application broken into **independent services, each focused on a specific functionality**, communicating over the network | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Microservices advantages | Independent **scaling, deployment, technology choice (polyglot), fault isolation, team ownership** | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Microservices disadvantage | **Operational overhead** — networking, service discovery, observability, more things to test/deploy/maintain | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Ingress (one-liner) | API object managing external access to services in a cluster; **traffic routing is controlled by rules** (path- or host-based) | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| Data layer in microservices | Per-service data stores; relational scale-out via **replication** and/or **sharding**; shared consistent state via a distributed key/value store | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |
| etcd | Distributed, reliable **key/value store**; consistency via the **Raft** consensus algorithm; also the Kubernetes control-plane datastore | [02-01](02-cloud-native-architecture/01-monolithic-vs-microservices.md) |

## 03 · Containers with Docker

_Not started._

## 04 · Kubernetes Fundamentals

_Not started._

## 05 · Kubernetes Deep Dive

_Not started._

## 06 · Telemetry and Observability

_Not started._

## 07 · Cloud Native Application Delivery

_Not started._
