# KCNA Study Guide

Exam-focused notes for the **Kubernetes and Cloud Native Associate (KCNA)** exam, built while working through James Spurin's Udemy course *KCNA: Kubernetes and Cloud Native Associate* and expanded with the definitions, comparisons, and context that make each fact stick.

The KCNA is a multiple-choice exam, so these notes optimize for recall: canonical definitions, "which component/project does X", dates, defaults, and comparison tables. Every chapter ends with an *Exam angle* section describing what a question on that topic looks like.

This is the second of five certifications on the road to CNCF [Kubestronaut](https://www.cncf.io/training/kubestronaut/) status. The first, CKAD, has its own repo: [ckad-exam-prep](https://github.com/caseythecoder90/ckad-exam-prep).

## Who this is for

- Anyone preparing for the KCNA who wants dense, skimmable notes plus recall sheets to drill from.
- Engineers new to the cloud native ecosystem who want a structured map of what the CNCF projects are and how they fit together.
- People collecting the Kubestronaut set who need the KCNA out of the way efficiently.

You do not need to read it front to back. Jump to a section, or drill the recall sheets the week before the exam.

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
│   ├── exam-facts.md                        # recall sheet: dates, versions, ports, defaults, personas
│   ├── cncf-projects.md                     # project cheat sheet: name, category, maturity, purpose
│   ├── commands/                            # per-topic command references from the hands-on lectures
│   ├── commands.md                          # global single-file command reference (Ctrl+F)
│   └── NOTES-WORKFLOW.md                    # how these notes are authored
├── tools/diagrams/                          # shared PlantUML theme + render script for every diagram
├── examples/                                # runnable manifests / Dockerfiles from the labs (growing)
└── extras/                                  # beyond the exam: e.g. a Keycloak contributor starter guide
```

## Contents

| Section | Covers | Status |
|---|---|---|
| [01 · Cloud Native Introduction](notes/01-cloud-native-introduction/) | What cloud native is (and isn't), the CNCF, the four philosophies, how to tell if an app is cloud native | In progress |
| [02 · Cloud Native Architecture](notes/02-cloud-native-architecture/) | Monolith vs microservices; characteristics and pillars; self-healing, automation, CI/CD, secure by default, serverless, service discovery; autoscaling, personas, community/governance, open standards | In progress |
| [03 · Containers with Docker](notes/03-containers-with-docker/) | Container history, images, layers, registries, Docker vs containerd, hands-on Docker | Not started |
| [04 · Kubernetes Fundamentals](notes/04-kubernetes-fundamentals/) | Architecture, control plane and node components, Pods, kubectl, namespaces, labels | Not started |
| [05 · Kubernetes Deep Dive](notes/05-kubernetes-deep-dive/) | Workloads, Services, networking, storage, scheduling, security/RBAC, Helm, operators, CRDs | Not started |
| [06 · Telemetry and Observability](notes/06-telemetry-and-observability/) | Logs, metrics, traces, Prometheus, Grafana, OpenTelemetry, cost management | Not started |
| [07 · Cloud Native Application Delivery](notes/07-cloud-native-application-delivery/) | GitOps, CI/CD, Argo CD, Flux, delivery patterns | Not started |

Section descriptions beyond 01 are placeholders based on the course outline and will be refined as each section is written.

## How to use it

1. **Learn a topic** — read its chapter in `notes/<section>/`. Definitions come first, then the mechanics, then an *Exam angle* section with the distractors to watch for.
2. **Drill the facts** — [`notes/exam-facts.md`](notes/exam-facts.md) is one line per fact the exam can ask about. [`notes/cncf-projects.md`](notes/cncf-projects.md) maps every project the course mentions to its category and purpose.
3. **Run the labs** — the course is hands-on even though the exam is not. [`notes/commands.md`](notes/commands.md) collects the Docker and kubectl commands from the lectures; [`examples/`](examples/) holds the manifests.
4. **Cross-reference the official sources** — each chapter links the canonical kubernetes.io, cncf.io, or project documentation it draws from.

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

## Roadmap

- **Notes for every course section** (01 through 07), one chapter per lecture topic.
- **`exam-facts.md` and `cncf-projects.md`** kept in sync with every chapter so they are complete by the time the course is.
- **`examples/`** — every manifest and Dockerfile from the hands-on lectures, runnable against a local cluster.
- **Practice-question review** — after finishing the course quizzes (section 8), a pass over the recall sheets to close any gaps.

## Extras

Not exam material, but grown out of it: [`extras/keycloak-starter-guide.md`](extras/keycloak-starter-guide.md) is a step-by-step path into contributing to Keycloak (CNCF incubating, Java/Quarkus) — run it, learn the architecture, build from source, trace requests with a debugger, write a test the project's way, land a first PR.

## Attribution & license

Notes were built while working through James Spurin's KCNA course and expanded with additional depth from the official CNCF and Kubernetes documentation. They are original write-ups intended for study and sharing; no course material is reproduced. Every diagram is an original PlantUML drawing (source `.puml` committed next to the rendered `.svg`), not a course slide.

This repository is dual-licensed (see [`LICENSE`](LICENSE)):

- **Notes & documentation** (`notes/`, diagrams, this README) — [CC BY 4.0](LICENSE-CC-BY-4.0). Reuse and adapt freely, including commercially, with attribution.
- **Code** (`examples/`, scripts, manifests, Dockerfiles) — [MIT](LICENSE-MIT).
