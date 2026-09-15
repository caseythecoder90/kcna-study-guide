# 01 — What is Cloud Native?

## 1. The official definition

The CNCF maintains the canonical definition (v1.1, approved by the TOC and Governing Board on 2024-02-26). The parts that matter for the exam:

- Cloud native practices let organizations develop, build, and deploy workloads in **public, private, and hybrid clouds** at scale, in a **programmatic and repeatable** manner.
- Cloud native systems are **loosely coupled** and interoperate in a way that is **secure, resilient, manageable, sustainable, and observable**.
- Typical building blocks (the list is explicitly non-exhaustive): **containers, service meshes, multi-tenancy, microservices, immutable infrastructure, serverless, declarative APIs**.
- Combined with **robust automation**, this lets engineers make **high-impact changes frequently and predictably with minimal toil**.

"Cloud native" is about *how* an application is designed and operated, not *where* it runs.

---

## 2. Two facets: architecture and culture

The course splits the term into two halves that always travel together.

| Facet | Definition | What it looks like |
|---|---|---|
| **Cloud Native Architecture** | An application that is built and designed using cloud native best practices | Microservices, containers, declarative config, automated delivery, self-healing, autoscaling |
| **Cloud Native Culture** | Different personas promote and drive change using cloud native practices | DevOps, SRE, FinOps (and others) working across team boundaries with shared automation and shared ownership |

The personas named in the lecture — **DevOps, SRE, FinOps** — come back in the *Personas* lecture of Section 2. For now the point is that architecture alone isn't enough; the people and processes around the application have to change too.

---

## 3. Is my application cloud native?

Moving an application to a cloud provider gives you three things whether or not the application changes at all:

| You get this for free | Why it helps |
|---|---|
| **Benefits from cloud infrastructure** | Cost-saving opportunities vs legacy on-prem; capacity can be scaled as required |
| **Guaranteed availability** | The provider will often guarantee a level of availability (an SLA) within a specific region |
| **Cloud provider API** | Everything is automatable, especially with infrastructure-as-code tools such as Terraform and Ansible |

None of that makes the application cloud native. The questions that actually decide it:

1. Is the application **automated** in its setup and delivery?
2. Has it been designed with **resilience** to protect from failure?
3. Can it **automatically scale** based on its operational workload?
4. Is it **secure by default**?

![Is my application cloud native? Cloud benefits vs the questions that decide it](./diagrams/01-is-my-application-cloud-native.png)

A lift-and-shift monolith on a cloud VM ticks the three left-hand boxes and none of the four on the right. That is "running in the cloud", not "cloud native".

---

## 4. Containers != Cloud Native

The most common misconception the lecture calls out:

> "Cloud Native is all about running my application in a container."

A container is a **packaging and isolation** mechanism. It says nothing about whether the application inside it is automated, resilient, scalable, or secure. A monolith copied into a Docker image, deployed by hand, unable to self-heal or scale, is still not cloud native — it is a containerized legacy application.

Containers are one of the building blocks in the CNCF definition, alongside microservices, service meshes, immutable infrastructure, declarative APIs, and serverless. Cloud native is the combination of those building blocks *plus* the automation and design practices around them.

---

## 5. Cloud native philosophies

The course organizes the rest of Section 2 around four philosophies. Each one gets its own lecture.

| Philosophy | What it covers |
|---|---|
| **Architecture** | How cloud native applications are designed: microservices, resilience, autoscaling, serverless, immutable infrastructure |
| **Personas** | The roles that make cloud native work: DevOps, SRE, FinOps, platform/security/data engineers, and how they collaborate |
| **Community and Governance** | How the CNCF and its projects are run: the TOC, SIGs, project maturity levels, open governance |
| **Open Standards** | The specifications that keep the ecosystem interoperable: OCI, CRI, CNI, CSI, and others |

![The four cloud native philosophies](./diagrams/02-cloud-native-philosophies.png)

---

## 6. The Cloud Native Computing Foundation (CNCF)

The CNCF is the vendor-neutral home for cloud native open source projects and is described in the course as "a driving force for cloud native, influential in its success". It is part of the **Linux Foundation**.

How it came to exist:

| Year | Event |
|---|---|
| **2014** | Kubernetes is open-sourced by **Google** |
| **2015** | Kubernetes is donated to the newly formed CNCF — the **first ever CNCF project** |

![CNCF formation timeline: Kubernetes open-sourced 2014, donated to the CNCF 2015](./diagrams/03-cncf-formation-timeline.png)

Kubernetes being the seed project is why the KCNA is "Kubernetes *and* Cloud Native": Kubernetes is the anchor, and the surrounding CNCF projects (Prometheus, Envoy, containerd, Helm, Argo, and so on) are the ecosystem that grew around it. Those projects are tracked in [`../cncf-projects.md`](../cncf-projects.md) as the course introduces them.

---

## Exam angle

- Expect a question that asks for the **defining property** of cloud native and offers "runs in a container" or "runs on a public cloud" as distractors. The correct framing is design and operational practice: automation, resilience, scalability, security, observability, loose coupling.
- Know the CNCF definition's list of **example technologies** (containers, service meshes, microservices, immutable infrastructure, serverless, declarative APIs, multi-tenancy) and its list of **system properties** (secure, resilient, manageable, sustainable, observable). A question can ask which item does *not* belong.
- **2014 / 2015 / Google / first CNCF project** — the Kubernetes origin facts are a reliable easy question.
- The CNCF is part of the **Linux Foundation**. A distractor will offer Google, the Apache Foundation, or the OpenStack Foundation.
- Cloud native has a **culture** component with named personas (DevOps, SRE, FinOps). A question may ask which persona is *not* a cloud native role, or which one owns cost.
- Cloud benefits (cost, regional availability SLAs, provider APIs) are things a cloud *provider* gives you; they are not what makes an *application* cloud native.

## References

- [CNCF Cloud Native Definition v1.1](https://github.com/cncf/toc/blob/main/DEFINITION.md) — the canonical definition, with the technology and property lists quoted above
- [Who we are — CNCF](https://www.cncf.io/about/who-we-are/) — the foundation's mission and its relationship to the Linux Foundation
- [Kubernetes — Overview](https://kubernetes.io/docs/concepts/overview/) — includes the "Going back in time" history from traditional to virtualized to container deployment
- [CNCF Landscape](https://landscape.cncf.io/) — the interactive map of every CNCF project by category and maturity
