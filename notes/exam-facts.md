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
| Four characteristics of cloud native applications | **Resilience, agility, operability, observability** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Four pillars of cloud native architecture (MCDC) | **Microservices, Containerisation, DevOps, Continuous Delivery** — "Morning Coffee Delivers Caffeine Delight" | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Self-healing chain | **Deployment** (declarative desired state + replica count) → **ReplicaSet** (managed by the Deployment; maintains the desired number of Pods) → **Pod** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Pod (one-liner) | **Smallest deployable unit** in Kubernetes; one or more containers with **shared networking and storage**; "think of a Pod as an isolated host" | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Which object directly maintains the Pod count? | The **ReplicaSet** (the Deployment manages the ReplicaSet) | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Continuous Integration | Every commit automatically **built, unit-tested, integration-tested** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Continuous Delivery | Changes automatically built, tested and made **deployable / released to an acceptance environment**; the production release is a **manual (human) decision** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Continuous Deployment | "Goes a step further" — every passing change goes to **production automatically, no human step**; needs strong automated testing and **rollback** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Bare "CD" / "CI/CD" on the exam | Read as Continuous **Delivery** unless the question says "deployment" or "automatically to production without manual intervention" | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Zero trust | "**Never trust, always verify**" — no trust from network location; verify every access, even inside the perimeter; always use **mTLS** between services | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| mTLS vs TLS | TLS validates **one** side (the server); **mutual** TLS validates **both** sides and encrypts the traffic | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Secure by default — the three practices | **Zero trust · secure channels · least privilege** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Secure channel vs zero trust | Secure channel = encryption/integrity of traffic **in transit** (TLS). Zero trust = a **trust model**: identity + authorization verified on every request regardless of location. mTLS is where they overlap | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Least privilege | Each identity gets only the permissions its job needs — RBAC, scoped ServiceAccounts, securityContext (non-root, dropped capabilities) | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Knative | Kubernetes **serverless** solution providing **scale to zero**; CNCF incubating Mar 2022 → **Graduated Sep 2025** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Serverless (course framing) | Run nothing when there are no requests; scale with demand in both directions; pay only for what is used | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Service discovery (definition) | Process of **finding the individual instances that make up a service**; automatic detection, minimal manual configuration | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Service discovery in Kubernetes | **Environment variables and DNS**; DNS is preferred; env vars only include Services that **existed before the Pod was created** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Kubernetes Service DNS name | `<service>.<namespace>.svc.cluster.local`, served by CoreDNS | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Terraform vs Ansible | Terraform = **infrastructure as code**, declarative provisioning via provider APIs (HashiCorp). Ansible = **configuration management / automation**, procedural playbooks, agentless (Red Hat). Neither is CNCF | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Application automation checklist | Speed & agility ✓ · rapid infrastructure + application deployment ✓ · frequent updates ✓ · **manual steps ✗** | [02-02](02-cloud-native-architecture/02-cloud-native-practices.md) |
| Autoscaling (definition) | A pattern for **automatic scaling of infrastructure or application components according to metrics or other requirements** | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Automatic vs automated | **Automatic** = works independently; **automated** = a process made independent of human intervention | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Three autoscaling triggers | **Reactive** (metric crosses a threshold) · **Scheduled** (known time, e.g. Black Friday) · **Predictive** (AI/ML forecast) | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Vertical scaling | Add CPU/RAM/storage to **one machine** ("scaling up"); bare metal has a hard ceiling and steep cost; usually means a **hypervisor** (e.g. VMware ESXi) giving a VM more of its host — capped by what the host has free | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Horizontal scaling | **Commodity machines working together as a distributed system**; add/remove resources relative to existing ones ("scaling across"); the cloud native default | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Cost of horizontal scaling | Increased **complexity of data sharing** — more instances = more routes and **concurrency**; testing is critical | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Cluster Autoscaler | Adjusts the **size of the cluster (nodes)** when Pods **fail to run for insufficient resources** (add) or nodes are **underutilized** and their Pods fit elsewhere (remove) | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HorizontalPodAutoscaler (HPA) | **Built in**; scales the **number of replicas** of a Deployment/StatefulSet from CPU/memory (metrics-server) or custom/external metrics | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| VerticalPodAutoscaler (VPA) | **Add-on** (not shipped with Kubernetes); scales a Pod's **resource requests and limits**; typically restarts the Pod to apply | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA + VPA together | Don't use both on the same CPU/memory metric for one workload — they conflict | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| KEDA | **Kubernetes Event-Driven Autoscaling**; CNCF **graduated Aug 2023** (sandbox Mar 2020, incubating Aug 2021); scales on external events via **ScaledObject** triggers; **can scale a Deployment to zero** | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| KEDA mechanics | Handles **0 → 1** itself; creates and feeds an **HPA** for **1 → n**; scale-to-zero impossible with CPU/memory triggers (nothing to measure) | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| KEDA trigger examples | Kafka lag, RabbitMQ / AWS SQS / Azure Service Bus queue length, Prometheus query, `cron` (gives scheduled scaling) | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Knative vs KEDA | Both reach zero. Knative = serverless **application platform** (request-driven, eventing). KEDA = an **autoscaler** attached to ordinary Deployments | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA control loop period | Every **15 s** by default (`--horizontal-pod-autoscaler-sync-period` on kube-controller-manager) | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA formula | `desiredReplicas = ceil(currentReplicas × currentMetricValue / targetMetricValue)`; readings within **10%** of target are ignored | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA with several metrics | Computes a desired count per metric and uses the **largest** | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA `Utilization` targets | Usage is a **percentage of the container's resource request** — no request, no metric, no scaling on it | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA scale-down stabilization | Default **300 s** window before removing Pods; scale-up is immediate | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| HPA API versions | `autoscaling/v1` = CPU only (what `kubectl autoscale` creates); **`autoscaling/v2`** = memory, multiple metrics, custom/external metrics, `behavior` | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| What the HPA can target | Anything with a `scale` subresource: Deployment, StatefulSet, ReplicaSet — not a bare Pod or DaemonSet | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| metrics-server | Add-on that serves the **Metrics API (`metrics.k8s.io`)** from kubelet data; needed by HPA, VPA and `kubectl top`; not installed by default | [02-03](02-cloud-native-architecture/03-autoscaling.md) |
| Serverless (meaning) | **Not** "no servers" — the servers belong to and are managed by the provider; you never choose cores, memory, networking, or patch hardware; you interact via **code or container images** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Serverless model | **Event → Execution → Billing**; billed for duration (per ms) × memory plus requests; **idle costs nothing** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| FaaS | **Function as a Service** — AWS Lambda is the reference example (also Azure Functions, Google Cloud Functions) | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Lambda deployment packages | Code as a **.zip file** or as a **container image** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Lambda's four promises | No infrastructure to manage · auto-scales from a dozen events/day to hundreds of thousands/s · pay per ms of compute · tune memory size, **provisioned concurrency** for double-digit ms latency | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Lambda free tier | **1 million requests** free per month | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Cold start | First request to a function with no warm environment: create environment → load runtime + code → run init → handle; hundreds of ms to seconds (JVMs slowest) | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Provisioned concurrency | Execution environments **pre-initialized and kept warm** → no cold start, **double-digit ms**; **billed continuously** even when idle; for latency-sensitive interactive workloads | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Reserved concurrency | A **cap and guarantee** on a function's concurrent executions (protects downstream systems); **free** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Serverless scaling limits | Native autoscaling from **zero**, bounded by the **account concurrency quota** (Lambda classic default 1,000/Region, soft), function **timeout**, reserved concurrency, and your **budget** — runaway bills are the serverless failure mode | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Kubernetes serverless options (course) | **Knative** and **OpenFaaS** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Knative Serving | Knative **Service** → URL, immutable **revisions**, **traffic splitting**; autoscaler + **activator** scale revision Pods **0 → n → 0** on in-flight requests | [02-04](02-cloud-native-architecture/04-serverless.md) |
| Knative Eventing | Sources → **Broker + Trigger** → sink, carried as **CloudEvents** | [02-04](02-cloud-native-architecture/04-serverless.md) |
| OpenFaaS | Functions packaged as **OCI images** deployed on Kubernetes; scales to zero; **not a CNCF project** (OpenFaaS Ltd; Community Edition + Pro) | [02-04](02-cloud-native-architecture/04-serverless.md) |
| CloudEvents | CNCF **specification for describing event data in a common way**; **Graduated Jan 2024** (accepted May 2018, incubating Oct 2019); CNCF Serverless Working Group | [02-04](02-cloud-native-architecture/04-serverless.md) |
| CloudEvents required attributes | `id`, `source`, `specversion`, `type` (optional: `time`, `subject`, `datacontenttype`, `dataschema`) | [02-04](02-cloud-native-architecture/04-serverless.md) |
| CloudEvents SDKs / bindings / formats | SDKs: Go, Java, JavaScript, Python, Ruby, Rust, C#, PHP, PowerShell · bindings: **AMQP, HTTP, Kafka, MQTT, NATS, WebSockets** · formats: JSON, Avro, Protobuf, XML | [02-04](02-cloud-native-architecture/04-serverless.md) |
| TOC | **Technical Oversight Committee** — the CNCF's technical governing body: technical vision, **accepts projects and moves them between levels**, aligns interfaces | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| TOC composition | **11 members**, two-year staggered terms: **6** elected by the Governing Board, **2** by end users, **1** by project maintainers, **2** by the TOC | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Governing Board (GB) | The **business** body — budget, marketing, trademarks; does *not* approve projects | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| End User TAB | End User **Technical Advisory Board** — voice of end users, advisory to the TOC, elects 2 TOC seats | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| CNCF maturity levels | **Sandbox → Incubating → Graduated** (+ **Archived** for inactive projects); a *signal to adopters* about which enterprises should adopt | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Maturity ↔ Crossing the Chasm | Sandbox = **Innovators** (techies) · Incubating = **Early adopters** (visionaries) · Graduated = **Early majority** (pragmatists); late majority/laggards have no level. Book by **Geoffrey Moore** | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Sandbox | Entry point; **low barrier, low reward, not compulsory**; four goals: public visibility of experiments, optional alignment with existing projects, nurturing, removing legal/governance obstacles | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Incubating | Production use by **≥ 3 independent adopters**; healthy committers; substantial flow of commits; clear versioning; specs need a reference implementation. **The significant barrier — most due diligence happens here** | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Graduated | Adds: committers/maintainers from **≥ 2 organizations**, **third-party security audit**, documented governance; the "obvious path" from incubating | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Sustainability signals (all levels) | Adoption · healthy rate of changes · committers from multiple orgs · **CNCF Code of Conduct** · **OpenSSF Best Practices Badge** (formerly **CII** — Core Infrastructure Initiative) | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Level-move process | Application → **TOC sponsor** → **TAG** presentation/recommendation → due diligence (**5–7 adopter interviews**) → **two weeks** public comment → **TOC vote, 2/3 supermajority** | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| SIG | **Special Interest Group** — Kubernetes' own working structure (SIG Network, SIG Node…); also the CNCF's *former* name (2019–2021) for what are now TAGs | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| TAG | **Technical Advisory Group** — CNCF domain groups: technical guidance, guide Sandbox onboarding, review level moves, coordinate needs of the TAG's users | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| SIG → TAG rename | CNCF SIGs created **June 2019** (37 projects); renamed **TAGs in February 2021** to end confusion with Kubernetes SIGs (Kubernetes used the term first and kept it) | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| TAGs 2021–2025 (the course's list) | App Delivery · Contributor Strategy · Environmental Sustainability · Network · Observability · Runtime · Security · Storage | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| TAGs since May 2025 | **Developer Experience · Infrastructure · Operational Resilience · Security and Compliance · Workloads Foundation** + TOC SubProjects: Contributor Strategy & Advocacy, Mentoring, Project Reviews | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| First CNCF projects | **Kubernetes** first (2015; first to **graduate** Mar 2018) · **Prometheus** second (May 2016; second to graduate Aug 2018) · **Envoy** graduated third (Nov 2018; created at Lyft) | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| KubeCon + CloudNativeCon | The CNCF's **flagship conference** (Linux Foundation), several editions a year; talks selected via **CFP** — call for proposals | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| KCD | **Kubernetes Community Day** — regional, **community-organised**, CNCF-supported 1–2 day event; each runs its own CFP; tiered since 2026 (first-time ≤ 200, tier 1 ≥ 350, tier 2 ≤ 600 attendees) | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| CNCF Ambassadors | Recognised **community leaders** who advocate, organise KCDs/meetups, speak, write and mentor; selected by application | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| CNCF community channels | CNCF Slack (`slack.cncf.io`), project mailing lists, `glossary.cncf.io`, **CLOTributor** (`clotributor.dev`) for contribution issues, LFX Mentorship | [02-05](02-cloud-native-architecture/05-community-and-governance.md) |
| Course personas | DevOps Engineer · Site Reliability Engineer · CloudOps Engineer · Security Engineer · DevSecOps Engineer · Full Stack Developer · Cloud Architect · Data Engineer (+ further study: FinOps Engineer, Data Scientist, ML Engineer) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| DevOps (definition) | Methodology in which **teams own the entire process from application development to production operations**; a **cultural** shift that removes hand-off queues ("throwing it over the wall") | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Dev vs Ops vs DevOps | Dev: development, speed/performance, CI/CD pipelines · Ops: has it been tested / documented / monitored? · DevOps: best of both, shared ownership | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| DevOps loop — eight phases | **Plan → Code → Build → Test → Release → Deploy → Operate → Monitor** (Monitor feeds the next Plan) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| DevOps skillset (course) | Infrastructure provisioning, sysadmin, storage, networking, internet services, automation/scripting, CI/CD, Git, GitOps, configuration management, performance analytics and monitoring | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| SRE (definition) | Combines **operations and software engineering** — builds systems to run applications, automating operational tasks. "DevOps gets code to production; SRE ensures the code running in production works" | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| SRE focus | **Uptime, availability, scalability, resilience, robustness, ability to resolve unforeseen problems** | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| SLI | **Service Level Indicator** — a quantitative **measurement** (e.g. measured 97% uptime, 300 ms response) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| SLO | **Service Level Objective** — the internal **target** for an SLI (e.g. responses under 200 ms); set tighter than the SLA | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| SLA | **Service Level Agreement** — the **customer contract** with consequences if missed (e.g. 99.99% uptime) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Error budget | 100% − SLO; a 99.9% SLO ≈ 43 min downtime per 30-day month; when spent, reliability work outranks features | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| CloudOps Engineer | The DevOps loop with emphasis on the **operations half — deploy, operate, monitor** — on cloud provider resources and cloud tooling (Terraform, IaC, multi-cloud deployment) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Security Engineer focus | Broad knowledge · attack vectors · OS best practices · network-based security · external threat **detection** · external threat **reduction** | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| DevSecOps | **DevOps ∩ Security** — security built into **every phase** of the loop ("shift left"): scanning, signing, policy-as-code, runtime detection | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Full Stack Developer | Frontend, web frameworks, OS and mobile UI, backend, languages such as Go/Rust/C/C++/Python; interacts with many components | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Cloud Architect | Decides **target platforms**, **multi-cloud**, cloud tooling, **cloud native interoperability**, meets requirements, **interpersonal skills** | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Data Engineer | Provide access to data · scale en masse · **distributed processing** · algorithmic usage · **data set compliance** · **prevent vendor lock-in** | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| FinOps Engineer | Cloud **cost** accountability: visibility, allocation, optimisation; FinOps Foundation is a Linux Foundation project; OpenCost (CNCF) for Kubernetes cost | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Newer titles | **Platform Engineer** (internal developer platform, golden paths) · **AI Engineer** (products on foundation models) · **ML Engineer** (models to production / MLOps) · **Forward Deployed Engineer** (embedded with the customer) | [02-06](02-cloud-native-architecture/06-cloud-native-personas.md) |
| Open standard (definition) | A specification that is **openly accessible and can be freely adopted and implemented**; a key component of open source — one interface, many implementations | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI — Open Container Initiative | Founded **June 2015** by **Docker** (with CoreOS and others) under the **Linux Foundation**: open governance for **open industry standards around container formats and runtimes** | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI's three specifications | **image-spec** (how to bundle a filesystem into an image) · **runtime-spec** (how to run a filesystem bundle) · **distribution-spec** (registry API, built on the **Docker Registry HTTP API v2**) | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI runtime reference implementation | **runc**, donated by Docker — the first contribution to the OCI | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI-compliant runtimes | runc · crun (Red Hat, C) · gVisor/runsc (Google, user-space kernel) · Kata Containers (micro-VM per pod; QEMU or **Firecracker**). Firecracker itself is AWS's micro-VM monitor, not an OCI runtime | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| Image-spec tooling | Docker, **BuildKit**, **Podman**, **Buildah** build OCI images | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OCI workflow sentence | Download an OCI **image** → unpack into an OCI runtime **filesystem bundle** → run with an OCI **runtime** | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CRI — Container Runtime Interface | **gRPC** plugin interface between the **kubelet** and the container runtime: **RuntimeService** + **ImageService**; v1 API mandatory since 1.26 | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CRI implementations | **containerd** (built-in CRI plugin; default on kind/EKS/GKE/AKS; socket `/run/containerd/containerd.sock`) · **CRI-O** (Red Hat, CRI-only; `/var/run/crio/crio.sock`) | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| dockershim | The kubelet's built-in Docker adapter, **removed in Kubernetes 1.24**; Docker Engine now needs the external **cri-dockerd** adapter | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| Runtime chain | kubelet → **CRI** → containerd / CRI-O → **OCI runtime-spec** → runc / crun / gVisor / Kata → containers. Low-level runtime chosen per Pod with **RuntimeClass** | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CNI — Container Network Interface | Specification + libraries for **configuring network interfaces in Linux containers**; CNCF **Incubating** (May 2017), from CoreOS; plugins are **executables** in `/opt/cni/bin`, config in `/etc/cni/net.d` | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CNI operations | **ADD** (add container to network) · **DEL** (remove) · **CHECK** (verify) · **VERSION** (probe); spec 1.1 adds STATUS and GC | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| When CNI runs | Only at Pod **sandbox create (ADD)** and **delete (DEL)**, invoked by the **container runtime**; it creates a veth pair, assigns an IP via IPAM, sets routes, returns the Pod IP | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CNI is required by Kubernetes | Nodes stay **NotReady** until a CNI plugin is installed. Docker Desktop hides the setup; minikube hides it but can be overridden; **kubeadm requires** it | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| Calico | Most widely adopted CNI **provider** (Tigera; **not CNCF**): `calico`/`calico-ipam` CNI plugin + **Felix** (programs routes and iptables/eBPF, **enforces NetworkPolicy**) + **BIRD** (BGP) or VXLAN/IPIP; dataplanes: Linux iptables, **eBPF**, Windows HNS | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| NetworkPolicy enforcement | Kubernetes NetworkPolicy is an API object with **no built-in implementation** — the **CNI provider** (Calico's Felix, Cilium, …) enforces it; Flannel does not | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| Other CNI providers | **Cilium** (eBPF; CNCF **Graduated** Oct 2023) · Flannel (overlay, no policy) · AWS VPC CNI · Azure CNI | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CSI — Container Storage Interface | Standard so a storage vendor writes **one driver for every orchestrator** (Kubernetes, Mesos, Cloud Foundry, Docker); replaced **in-tree** volume plugins; GA in Kubernetes **1.13**; independent spec, not a CNCF project | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CSI services | **Identity** (capabilities, health) · **Controller** (create/delete/attach/snapshot; runs anywhere) · **Node** (stage/mount on the node; runs on every node) | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| CSI implementations (course) | **Rook** — open source, CNCF **Graduated Oct 2020**, storage orchestration for Kubernetes (Ceph) · **Portworx** — commercial, Pure Storage | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| SMI — Service Mesh Interface | **A standard interface for service meshes on Kubernetes** (smi-spec.io) — basic feature set, room to innovate. **Archived by the CNCF 25 Sep 2023**; work moved to the Kubernetes **Gateway API (GAMMA)** | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OpenMetrics | Prometheus exposition format spun out as a standard (2018); **archived July 2024** and merged back into Prometheus | [02-07](02-cloud-native-architecture/07-open-standards.md) |
| OpenTelemetry (maturity) | CNCF **Graduated May 2026** (accepted 2019, incubating 2021); merger of OpenTracing and OpenCensus | [02-07](02-cloud-native-architecture/07-open-standards.md) |

## 03 · Containers with Docker

| Fact | Value | Chapter |
|---|---|---|
| Mainframe | Large centralised computer built for **throughput and reliability** (IBM System/360 1964 → IBM Z / z/OS today); shared by many users via **time sharing** | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| CP/CMS | IBM mainframe OS, **late 1960s–early 1970s**: unlike pure time sharing, the Control Program gave **each user their own virtual machine** running CMS — one of the **earliest uses of virtual machines** | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Time sharing | A method of sharing a large computer among **multiple users simultaneously** — shared processor and storage, one OS | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| chroot | **Version 7 Unix, 1979**; **changes the root directory for a process and its children** — they see only files under the new root. Limited: hostname/IPs still visible, root can escape, dirs must be root:root. Uses: confined SSH shells, Apache, user isolation | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| FreeBSD Jails | **FreeBSD 4.0, 2000**; partitions FreeBSD into isolated environments with **own users, processes, filesystem, and networking stack**; popular with ISPs early 2000s; held back by **complexity** — ease of use decides adoption | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| BSD | **Berkeley Software Distribution** — the Unix flavour FreeBSD is based on | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Solaris Zones / HP-UX vPars | Sun **Zones**: Solaris divided into isolated environments (2005). HP-UX **Virtual Partitions**: logical partitions of an HP-UX system | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Virtual machine | **Software emulation of a physical computer**; each VM runs a full guest OS with its own kernel | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Hypervisor | Lets multiple VMs run across physical compute — an **abstraction layer between physical resources and guests**; over time merged with the OS (ESXi, KVM, Hyper-V); supports live migration, GPUs, cloud, **VDI** | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| VMware | Market leader in virtualisation; hypervisor **ESXi**, management **vCenter** | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Linux namespaces (origin) | Introduced **2002, kernel 2.4.19**; **originally 6**: **user, pid, network, mount, uts, ipc** (exam answer: 6). Later: cgroup (4.6, 2016), time (5.6, 2020) | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Namespace (definition) | Wraps a **global system resource** so processes inside appear to have **their own isolated instance** of it; created with `clone`/`unshare`, joined with `setns`; visible in `/proc/<pid>/ns/` | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| user namespace | Isolates **user and group IDs** — UID 0 inside can map to an unprivileged UID outside (rootless containers) | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| pid namespace | Own **process ID** tree; the container's first process is **PID 1**; cannot see host or other containers' processes | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| network namespace | Own **networking stack**: interfaces, IPs, routes, **port space**; Pod containers share one | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| mount namespace | Own **filesystem hierarchy / mount points**; the container's / is its image rootfs | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| uts namespace | Isolates **hostname and domain name** (UTS = Unix Time-Sharing) | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| ipc namespace | Own **inter-process communication** objects — POSIX/System V message queues, shared memory | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| cgroups (control groups) | Kernel feature to **group processes hierarchically and limit/monitor their resource usage**. Started at **Google 2006** as "process containers", renamed, **released 2007, merged 2008** (kernel 2.6.24); v2 unified hierarchy official in 4.5 (2016). The course's "7th namespace" | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| cgroups' four capabilities | **Resource limits** (how much CPU/memory) · **Prioritisation** (shares when contended) · **Accounting** (measure and report) · **Control** (start/stop/freeze/restart the group) | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Namespaces vs cgroups | Namespaces limit what a process can **see** (visibility); cgroups limit what it can **use** (resources) | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Container (definition) | An ordinary host process isolated by **namespaces**, budgeted by **cgroups**, with a filesystem from an **image**, running on the **host's shared kernel** — no guest OS, no hypervisor | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Shared kernel — the benefit over VMs | No guest OS per workload → **MB not GB, milliseconds not minutes, hundreds per host, near-zero overhead, one kernel to patch**. Cost: **weaker isolation** than a VM and containers must match the host kernel's OS family | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| uname demo | `docker run ubuntu|amazonlinux|centos uname -a` all print the **same kernel** (e.g. 5.15.49-linuxkit on Docker Desktop) — the shared kernel made visible; only userspace differs | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Docker (history) | Founded **2010 as dotCloud** (a PaaS); tooling **open-sourced and renamed Docker in 2013**; written in Go | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Docker's two key ingredients | **Linux kernel isolation** (namespaces + cgroups, shared kernel) + **ease of use** (images, simple CLI). Success attributed to **simplicity** | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Why containers over VMs (exam phrasing) | Lightweight, fast to start, portable, dense, efficient — because they **share the host kernel** instead of booting a guest OS | [03-01](03-containers-with-docker/01-introduction-to-containers.md) |
| Traditional Docker (Linux) stack | Hardware → Linux (host kernel) → **containerd + runc** (the runtime Docker uses) → containers via the Docker CLI | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker minimum kernel | Course slide: **3.1, released 2011**. Docker's docs: **3.10 or higher** (June 2013). Use the course figure if the options match it | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker on a VM | Hardware is rarely a concern; in virtual environments **check virtualisation is enabled** | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker Desktop — what runs Docker | A **hidden, isolated Linux virtual machine**; containers run inside it on a LinuxKit kernel | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker Desktop VM backends | **Windows:** WSL 2 (default) or Hyper-V · **macOS:** Apple Virtualization framework / Docker VMM (course: HyperKit, QEMU) · **Linux:** KVM + QEMU | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker Desktop's main advantage | Runs Docker on **Windows and macOS** with a **GUI**, plus **bundled Kubernetes** and **Extensions** — convenience, not performance | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Resource management on a Mac | Done in Docker Desktop **Settings → Resources** (CPU, memory default 50% of host, swap, disk) because limits apply to the **VM**; Linux Engine containers use the host directly; Windows WSL 2 uses `.wslconfig` | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Docker Extensions | Marketplace of **third-party tools that plug into the Docker Desktop UI** (log viewers, disk usage, DB GUIs, scanners) | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Kubernetes in Docker Desktop | Settings → Kubernetes → Enable; single node named **docker-desktop**, role control-plane, context `docker-desktop`; provisioner kubeadm (single node) or kind (multi-node) | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| `docker run <image>` | **Creates and starts a container** from an image, pulling it first if needed | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| `-i` flag | `--interactive` — **keep STDIN open** so you can type into the process | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| `-t` flag | `--tty` — **allocate a pseudo-terminal** (a real shell prompt); `-it` together for an interactive shell | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| `-d` and `--rm` | `-d` detach (run in background, print the ID); `--rm` remove the container automatically when it exits | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Main container process | The command given to `docker run` becomes **PID 1** in the container; **when it exits the container stops** | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| What htop sees inside a container | All of the kernel's (VM's) CPUs and memory — `/proc/cpuinfo` and `/proc/meminfo` are **not namespaced**; cgroups limit usage without changing what is visible | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Windows containers | Docker Desktop on Windows can switch to **Windows containers** mode (needs a Windows kernel); Linux containers are the default | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |
| Apple silicon | Images default to **arm64** (`aarch64` in uname); x86 images run under emulation | [03-02](03-containers-with-docker/02-docker-setup-and-install.md) |

## 04 · Kubernetes Fundamentals

_Not started._

## 05 · Kubernetes Deep Dive

_Not started._

## 06 · Telemetry and Observability

_Not started._

## 07 · Cloud Native Application Delivery

_Not started._
