# 16 — Pod Security Admission

Chapter 05-14 introduced the Pod Security Standards and the controller that enforces them. Chapter 05-15 showed the `securityContext` fields they judge. This chapter is the enforcement in action: **Pod Security Admission (PSA) + Pod Security Standards (PSS)**, namespace by namespace.

> Pod Security Admission is **a feature responsible for checking your Pods before they are created**, making sure they meet the security standards you have set for your cluster.

---

## 1. Admission control: mutate, then validate

![Where Pod Security Admission sits](./diagrams/46-admission-pipeline.svg)

> Before the API server accepts a request, it is sent through **a series of admission controllers**. These can **mutate** the request, **validate** it, or **reject** it if it breaks certain rules.

> The API received your request → **Admission Control** → The object is stored in etcd and becomes reality.

The documentation describes **two phases, always in this order**:

| Phase | Does | Examples |
|---|---|---|
| **1. Mutating** | **Changes** the request — *injecting sidecars or adding defaults* | ServiceAccount token mounting, LimitRanger default requests, a service mesh's proxy injection, Kyverno mutate rules |
| **2. Validating** | **Accepts or rejects** — *rejecting Pods that don't meet security rules* | **PodSecurity**, ResourceQuota, NodeRestriction, OPA Gatekeeper, Kyverno validate rules |

> If any of the controllers in **either phase** reject the request, **the entire request is rejected immediately**.

**PSA is one validating controller** — the built-in `PodSecurity` plugin, *"Type: Validating"*, stable since **v1.25**. Running after mutation is deliberate: it judges the Pod **as it will actually be stored**, sidecars and defaults included.

---

## 2. What PSA asks, and how it decides

For every new Pod, PSA asks questions like:

- **Is the container running as root?**
- **Is it using host networking or host PID?**
- **Is it privileged?**
- **Is it mounting sensitive host paths?**

> Instead of defining complex, per-Pod policies, Pod Security Admission uses **standard security profiles** and **namespace labels** to decide what's allowed and what's not.

Those are the two halves — the **standard profiles** are the PSS levels, the **namespace labels** pick one per namespace.

### 2.1 The levels (PSS)

| Level | Lecture's summary |
|---|---|
| **Privileged** | **Basically "no restrictions".** Suitable for **system namespaces** or trusted workloads that **really do need host-level access**, like **CNI plugins or storage drivers** |
| **Baseline** | **Meant for most applications.** Blocks **known privilege-escalation paths** while staying compatible with common workloads. Rejects things like **privileged containers, hostPID/hostIPC, dangerous capabilities and host-related options** |
| **Restricted** | **"As locked down as reasonably possible."** Enforces current best practice — **no running as root, stricter capability rules, stronger requirements around securityContext fields** |

**A correction to the slide:** it says privileged suits *"trusted workloads that really **no** need host-level access"*. That is a typo — the point of the privileged level is the opposite. **These workloads genuinely *do* need host-level access** (a CNI plugin must configure the node's network; a storage driver must mount host devices), which is exactly why they cannot run under baseline.

The full list of what each level blocks is in chapter 05-14 section 3.1.

### 2.2 The modes

| Mode | Behaviour |
|---|---|
| **`enforce`** | **Actually block** non-compliant Pods |
| **`warn`** | **Allow** the Pod, but **send a warning to the user** |
| **`audit`** | **Allow** the Pod, but **log the violation** for auditing (an annotation on the audit log event) |

### 2.3 The labels

PSA works **at the namespace level**: label a namespace with the level you want, and the admission controller enforces it on any Pod created in that namespace.

```
pod-security.kubernetes.io/<MODE>: <LEVEL>
pod-security.kubernetes.io/<MODE>-version: <VERSION>
```

- **`<MODE>`** — `enforce`, `warn` or `audit`
- **`<LEVEL>`** — `privileged`, `baseline` or `restricted`
- **`<VERSION>`** — a Kubernetes minor version such as `v1.34`, or **`latest`**

**Modes are independent, and each can use a different level.** The lecture's example combines all three:

```
pod-security.kubernetes.io/enforce=privileged
pod-security.kubernetes.io/enforce-version=latest
pod-security.kubernetes.io/warn=baseline
pod-security.kubernetes.io/warn-version=latest
pod-security.kubernetes.io/audit=restricted
pod-security.kubernetes.io/audit-version=latest
```

Read it as: **block nothing, warn the user about anything worse than baseline, and record anything worse than restricted.** That is the gentle way to roll PSA out to an existing namespace — see what *would* break before enforcing it.

### 2.4 The `-version` label

The PSS rules evolve. The `-version` label pins which release's definition applies:

| Value | Meaning |
|---|---|
| **`latest`** | Always the current Kubernetes version's rules — tightens automatically on upgrade |
| **`v1.34`** (a specific version) | The rules as they were in that release — **an upgrade cannot start rejecting Pods** that passed before |

`latest` is convenient; pinning is safer for production namespaces, with the pin bumped deliberately after testing.

---

## 3. The lab

### 3.1 An unlabelled namespace

```bash
kubectl create namespace psa-unrestricted
kubectl get ns psa-unrestricted --show-labels
```

```
NAME               STATUS   AGE   LABELS
psa-unrestricted   Active   14s   kubernetes.io/metadata.name=psa-unrestricted
```

The only label is `kubernetes.io/metadata.name`, set automatically on every namespace (chapter 05-10). **No `pod-security` labels means the `privileged` level applies — nothing is checked.**

A deliberately insecure Pod, generated and then edited:

```bash
kubectl -n psa-unrestricted run insecure-pod --image=nginx:stable --dry-run=client -o yaml > insecure-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: insecure-pod
  name: insecure-pod
  namespace: psa-unrestricted
spec:
  hostNetwork: true          # the node's network namespace
  hostPID: true              # the node's process namespace
  containers:
  - image: nginx:stable
    name: insecure-pod
    securityContext:
      privileged: true       # near-full host access
      runAsUser: 0           # explicitly root
```

Four of the four questions in section 2 answered "yes".

```bash
kubectl apply -f insecure-pod.yaml
kubectl get pod -n psa-unrestricted
# insecure-pod   1/1   Running
```

**It runs.** With no labels, PSA has no level to enforce — the namespace is effectively privileged.

### 3.2 A baseline namespace

```bash
kubectl create namespace psa-baseline
kubectl label namespace psa-baseline \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=baseline \
  pod-security.kubernetes.io/warn-version=latest
```

The same Pod, with only its namespace changed:

```bash
cp insecure-pod.yaml insecure-pod-baseline.yaml     # namespace: psa-baseline
kubectl apply -f insecure-pod-baseline.yaml
```

```
Error from server (Forbidden): error when creating "insecure-pod-baseline.yaml":
pods "insecure-pod" is forbidden: violates PodSecurity "baseline:latest":
host namespaces (hostNetwork=true, hostPID=true),
privileged (container "insecure-pod" must not set securityContext.privileged=true)
```

How to read that message:

| Part | Meaning |
|---|---|
| `Forbidden` | Rejected at admission — the Pod was **never stored**, so it will not appear in `kubectl get pods` |
| `violates PodSecurity "baseline:latest"` | The **level** and **version** from the namespace labels |
| `host namespaces (hostNetwork=true, hostPID=true)` | First baseline check failed |
| `privileged (container ... must not set securityContext.privileged=true)` | Second baseline check failed |

Note what is **not** listed: `runAsUser: 0`. **Baseline permits running as root** — only **restricted** forbids it. The error names exactly the controls the chosen level checks.

---

## 4. Operating PSA

### 4.1 Labelling a namespace that already has Pods

Applying an `enforce` label to an existing namespace **does not delete or evict** anything:

> When an `enforce` policy (or version) label is added or changed, the admission plugin will **test each pod in the namespace against the new policy**. Violations are **returned to the user as warnings**.

Existing Pods keep running; only **new** Pods are rejected. That makes it easy to be surprised later — a Pod that restarts in place is fine, but if its node fails and the replacement is a *new* Pod, it is rejected.

**Preview before you commit** with a server-side dry run:

```bash
kubectl label --dry-run=server --overwrite ns psa-unrestricted \
  pod-security.kubernetes.io/enforce=baseline
```

```
Warning: existing pods in namespace "psa-unrestricted" violate the new PodSecurity enforce level "baseline:latest"
Warning: insecure-pod: host namespaces, privileged
namespace/psa-unrestricted labeled (server dry run)
```

The checks run; the label is not saved.

### 4.2 Pods versus workload resources

| Mode | Checks Pods | Checks Deployments, Jobs, StatefulSets... |
|---|---|---|
| **`enforce`** | **Yes** | **No** |
| **`warn`**, **`audit`** | Yes | **Yes** |

So with `enforce` alone, a non-compliant **Deployment is accepted** — and then **its ReplicaSet fails to create every Pod**. The only sign is a `FailedCreate` event on the ReplicaSet and a Deployment stuck at `0/3`:

```bash
kubectl describe replicaset <rs> | grep -A3 Events
# Warning  FailedCreate  ... violates PodSecurity "restricted:latest": ...
```

**Always pair `enforce` with `warn` at the same level** — then `kubectl apply` of the Deployment prints the warning immediately, before any Pod is attempted.

### 4.3 Exemptions

The admission controller's configuration can exempt requests from all three modes:

| Dimension | Exempts |
|---|---|
| **Usernames** | Requests from specific authenticated users |
| **RuntimeClassNames** | Pods using a specific runtime class (e.g. a sandboxed runtime, chapter 05-14) |
| **Namespaces** | Whole namespaces |

Exempting a user only helps when they create Pods **directly** — most Pods are created by controllers. And the docs warn **not** to exempt controller ServiceAccounts such as `replicaset-controller`, because that would exempt **anyone who can create a Deployment**.

### 4.4 Choosing levels per namespace

| Namespace | Typical labels |
|---|---|
| `kube-system`, CNI and storage namespaces | `enforce=privileged` — the workloads need host access |
| Ordinary application namespaces | `enforce=baseline`, `warn=restricted`, `audit=restricted` |
| Security-sensitive applications | `enforce=restricted` (+ `warn=restricted`) |
| Rolling out to an existing namespace | `warn` and `audit` only, then add `enforce` once clean |

---

## Exam angle

- **Pod Security Admission checks Pods before they are created** against the **Pod Security Standards**. It is the built-in **`PodSecurity`** admission controller — **type: validating**, **stable v1.25**, replacing PodSecurityPolicy.
- **Admission runs in two phases: mutating first** (inject sidecars, add defaults), **then validating** (reject non-compliant objects). A rejection in either phase rejects the whole request, and **nothing is stored in etcd**.
- **PSA works per namespace via labels** `pod-security.kubernetes.io/<mode>: <level>` and an optional **`<mode>-version`** (`latest` or a version like `v1.34`).
- **Levels: privileged** (no restrictions — system workloads that need host access) · **baseline** (blocks known escalations — privileged, hostPID/hostIPC/hostNetwork, dangerous capabilities, hostPath) · **restricted** (no root, drop all capabilities, strict securityContext).
- **Modes: `enforce`** blocks · **`warn`** allows with a user warning · **`audit`** allows and records in the audit log. **Each mode can use a different level.**
- **An unlabelled namespace is effectively `privileged`.** **Baseline still allows running as root**; only restricted forbids it.
- **`enforce` checks Pods only; `warn` and `audit` also check workload resources** — so an enforce-only namespace accepts a bad Deployment whose Pods then fail to create.
- **Adding an `enforce` label does not evict existing Pods** — it warns about them. Preview with **`kubectl label --dry-run=server`**.

## References

- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) — modes, labels, workload resources, exemptions
- [Enforce Pod Security Standards with Namespace Labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/) — labelling, versions and server-side dry runs
- [Admission Control in Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) — the mutating and validating phases and the `PodSecurity` plugin
