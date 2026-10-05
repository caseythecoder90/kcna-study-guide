# 07 — Affinity and anti-affinity

Chapter 05-05 covered `nodeSelector`: exact-match on node labels, and nothing else. Chapter 05-06 covered taints, which repel. Affinity is the expressive version of the attracting half — rules about **which nodes a Pod should run on**, and rules about **which other Pods it should run near or away from**.

---

## 1. The two types, and why there are exactly two

> - **`requiredDuringSchedulingIgnoredDuringExecution`**: The scheduler **can't schedule the Pod unless the rule is met**. This functions like `nodeSelector`, but with a more expressive syntax.
> - **`preferredDuringSchedulingIgnoredDuringExecution`**: The scheduler **tries** to find a node that meets the rule. **If a matching node is not available, the scheduler still schedules the Pod.**

![The two affinity types are the two halves of scheduling](./diagrams/16-required-vs-preferred.svg)

These are not two strengths of the same mechanism. **They plug into the two different stages of chapter 05-05:**

| | Stage | Behaviour | If nothing matches |
|---|---|---|---|
| **`required...`** | **Filtering** | Nodes that do not match are **removed from the feasible set** | The Pod stays **`Pending`** |
| **`preferred...`** | **Scoring** | Matching nodes get their **weight added to their score** | The Pod is **scheduled anyway**, somewhere else |

That is the whole of the study-tips page, and it is the distinction to carry into a question: **`required` is mandatory, `preferred` is best effort.** The giveaway is always *what happens when nothing matches*.

It also explains two asymmetries in the syntax that look arbitrary otherwise:

- **Only `preferred` has a `weight`.** Filtering is a yes/no question — there is nothing to rank.
- **Only `required` can leave a Pod `Pending`.** A score boost cannot block anything.

### What `IgnoredDuringExecution` means

> `IgnoredDuringExecution` means that **if the node labels change after Kubernetes schedules the Pod, the Pod continues to run.**

**Affinity is evaluated once, at scheduling time.** Remove the label that got a Pod placed and nothing happens to that Pod — in sharp contrast to a `NoExecute` taint (chapter 05-06), which *does* evict. The rule is only re-evaluated at the **next scheduling decision**: a delete, a rescheduled replica, or `kubectl replace --force`.

A `RequiredDuringSchedulingRequiredDuringExecution` variant was designed but **has never been implemented**, which is why every field name you will ever type ends in `IgnoredDuringExecution`.

---

## 2. Node affinity

> **Node affinity allows you to specify rules about which nodes your Pods should be scheduled to based on node labels**, specified in the Pod specification.

Conceptually `nodeSelector` with a real query language. It lives at **`spec.affinity.nodeAffinity`**.

### 2.1 The lab — a required rule

Label a node:

```bash
kubectl label node/worker-1 disktype=ssd
kubectl get nodes --show-labels
```

```
NAME       STATUS  ROLES    LABELS
worker-1   Ready   <none>   ...,disktype=ssd,kubernetes.io/hostname=worker-1,...
worker-2   Ready   <none>   ...,kubernetes.io/hostname=worker-2,...
```

Then ask for it:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: node-affinity
  name: node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - image: nginx
    name: node-affinity
```

The Pod runs on `worker-1`, because it is the only node carrying `disktype=ssd`.

**Change the manifest so the labels no longer match** — ask for `disktype=nvme` when no node has it — and redeploy:

```bash
kubectl replace --force -f node-affinity.yaml
kubectl get pods -o wide
```

The Pod is **`Pending`** with no node. `required` removed every candidate, and nothing is left. Add the label the Pod is now asking for:

```bash
kubectl label node/worker-2 disktype=nvme
kubectl replace --force -f node-affinity.yaml     # schedules onto worker-2
```

**`kubectl replace --force` is doing real work here** (chapter 04-03). Labelling the node is not enough on its own — a Pending Pod *would* eventually schedule, but an already-running Pod will not move, because `IgnoredDuringExecution`. `replace --force` deletes and recreates the Pod, which forces a fresh scheduling decision.

### 2.2 The structure, and the OR/AND rule

The nesting has four levels and the plurals matter:

```
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:            # a LIST of terms
  - matchExpressions:           # a LIST of expressions inside one term
    - key: ...
      operator: ...
      values: [...]
```

> If you specify **multiple terms in `nodeSelectorTerms`**, then the Pod can be scheduled onto a node if **one of the specified terms can be satisfied (terms are ORed)**.
>
> If you specify **multiple expressions in a single `matchExpressions`** field, then the Pod can be scheduled onto a node **only if all the expressions are satisfied (expressions are ANDed)**.

**Terms OR, expressions AND.** One more rule worth knowing:

> If you specify **both `nodeSelector` and `nodeAffinity`, *both* must be satisfied** for the Pod to be scheduled onto a node.

### 2.3 Operators

| Operator | Behaviour | Available in |
|---|---|---|
| **`In`** | The label value is **present in** the supplied set of strings | node + pod affinity |
| **`NotIn`** | The label value is **not contained in** the supplied set | node + pod affinity |
| **`Exists`** | **A label with this key exists** on the object (no `values`) | node + pod affinity |
| **`DoesNotExist`** | **No label with this key exists** | node + pod affinity |
| **`Gt`** | The label value parses as an integer and is **greater than** this integer | **`nodeAffinity` only** |
| **`Lt`** | The label value parses as an integer and is **less than** this integer | **`nodeAffinity` only** |

> **`NotIn` and `DoesNotExist` allow you to define node anti-affinity behavior.**

There is **no `nodeAntiAffinity` field** — negative operators are how you express it. (Taints are the other way to repel Pods from nodes, from chapter 05-06.) `Gt` and `Lt` fail scheduling outright if the value does not parse as an integer.

### 2.4 Preferred rules and weights

```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 20
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - nvme
      - weight: 10
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

Note the field name change: `required` holds **`nodeSelectorTerms`**, `preferred` holds **`preference`** under each weighted entry.

> You can specify a **`weight` between 1 and 100** for each instance... the scheduler **iterates through every preferred rule that the node satisfies and adds the value of the `weight` for that expression to a sum**. The final sum is **added to the score of other priority functions** for the node.

With `worker-2` labelled `disktype=nvme` and `worker-1` labelled `disktype=ssd`, the preference order is:

```
nvme (+20)   ->   ssd (+10)   ->   any node (+0, still scheduled)
```

**A preferred rule can still lose.** The weight is added to a total that other scoring functions also contribute to — if `worker-2` is heavily loaded, a +20 may not be enough to beat `worker-1`. This is the difference between "prefer" and "require" in one sentence: the preferred rule is an *input* to a decision, not the decision.

---

## 3. Inter-pod affinity and anti-affinity

![Three rules, and the only question that separates them](./diagrams/17-three-kinds-of-affinity.svg)

> Inter-pod affinity and anti-affinity allow you to **constrain which nodes your Pods can be scheduled on based on the labels of Pods already running on that node**, instead of the node labels.

One question separates all three rules: **whose labels am I reading?**

| | Reads | Means |
|---|---|---|
| **`nodeAffinity`** | **Node** labels | *"Put me on a node that looks like this"* |
| **`podAffinity`** | Labels of **Pods already running** | *"Put me where those Pods already are"* — co-location |
| **`podAntiAffinity`** | Labels of **Pods already running** | *"Keep me away from those Pods"* — separation |

**Pod affinity is the best-friend rule:** these Pods need to be together. **Pod anti-affinity is the opposite:** these Pods must not, or should not, share a place. The usual reasons for each:

| `podAffinity` | `podAntiAffinity` |
|---|---|
| Services that communicate constantly — co-locate for latency | **Distribute replicas** across nodes |
| Shared cache or local data locality | **Reduce the single point of failure** |
| Avoid cross-zone network charges | **Balance workloads** evenly |

Both take the same two forms as node affinity — `required` (a filter) and `preferred` (a score boost) — and both are `IgnoredDuringExecution`.

### 3.1 The lab — forcing two Pods onto the same node

A backend Pod carrying a label, and a frontend Pod that demands to be with it:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod-affinity-backend
    role: backend            # <- the label the other Pod will select on
  name: pod-affinity-backend
spec:
  containers:
  - image: redis
    name: pod-affinity-backend
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod-affinity-frontend
  name: pod-affinity-frontend
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:                       # selects PODS, not nodes
          matchExpressions:
          - key: role
            operator: In
            values:
            - backend
        topologyKey: kubernetes.io/hostname  # "same node"
  containers:
  - image: nginx
    name: pod-affinity-frontend
```

Read the rule out loud: **place this Pod only on a node that already has a Pod labelled `role=backend`.** Because `topologyKey` is `kubernetes.io/hostname`, "already has" means *on that exact machine*. The scheduler puts the frontend wherever the backend landed — or leaves it `Pending` if there is no such Pod anywhere.

Two structural differences from node affinity are worth noticing:

- **`labelSelector`, not `matchExpressions` directly.** The selector is a full label query, the same grammar as a Service selector (chapter 04-12), because it is selecting **Pods**.
- **`topologyKey` is a sibling of `labelSelector`** and is **mandatory**.

The `preferred` form has its own field-name trap. Node affinity wraps each weighted entry in **`preference`**; pod affinity wraps it in **`podAffinityTerm`**:

```yaml
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:            # NOT 'preference'
          labelSelector:
            matchLabels:
              app: web
          topologyKey: kubernetes.io/hostname
```

That one is the standard "spread my replicas, but run them all anyway" rule — the most common use of anti-affinity in practice. Swap it for `required` and the surplus replicas stay `Pending` once every node already holds one.

### 3.2 Namespaces

Pod labels are namespaced, so a Pod selector needs to know where to look.

> If omitted or empty, **`namespaces` defaults to the namespace of the Pod where the affinity/anti-affinity definition appears.**

There is also **`namespaceSelector`** (stable since **v1.24**), a label query over namespaces. **An empty `namespaceSelector` (`{}`) matches all namespaces**, while a null one falls back to the rule's own namespace.

### 3.3 The cost

> Inter-pod affinity and anti-affinity **require substantial amounts of processing which can slow down scheduling in large clusters significantly. We do not recommend using them in clusters larger than several hundred nodes.**

Node affinity carries no such warning — reading a node's labels is cheap. Pod affinity has to examine **the Pods already running across the cluster**, for every scheduling decision. For simple spreading, **topology spread constraints** are the cheaper modern tool.

---

## 4. topologyKey

![topologyKey — the word same has to mean something](./diagrams/18-topology-key.svg)

This is the part of pod affinity that has no equivalent anywhere else in Kubernetes, and it is the part that does not stick. The docs state the rule as a sentence with two blanks:

> *"This Pod **should (or should not) run in an X** if that **X is already running one or more Pods that meet rule Y**"*, where **X is a topology domain** like node, rack, cloud provider zone or region, and **Y is the rule**.

- **`labelSelector` is Y** — *which* Pods am I talking about?
- **`topologyKey` is X** — what counts as **the same place** as those Pods?

Without X the rule is meaningless. "Schedule me with the backend" — in the same *what*? The same machine, the same rack, the same region? Those are very different instructions, and **that is why `topologyKey` is required and may never be empty.**

### 4.1 It names a node label key, not a value

> You express the topology domain (X) using a `topologyKey`, which is **the key for the node label that the system uses to denote the domain**.

**Two nodes are in the same topology domain when they carry the same *value* for that key.**

| `topologyKey` | The domains it creates |
|---|---|
| **`kubernetes.io/hostname`** | `node-1` has `=node-1`, `node-2` has `=node-2` — **every node is its own domain**, because every value differs. "Same domain" means **same machine** |
| **`topology.kubernetes.io/zone`** | `node-1` and `node-2` both have `=us-east-1a` → **one** domain. `node-3` and `node-4` have `=us-east-1b` → a second. "Same domain" means **same availability zone**, across several machines |
| **`topology.kubernetes.io/region`** | Wider still — a whole geographic region |

**The narrower the scope, the more precise the placement control.** The same rule with a different `topologyKey` gives a completely different guarantee:

| Rule | `kubernetes.io/hostname` | `topology.kubernetes.io/zone` |
|---|---|---|
| **`podAffinity`** | Same physical host — fastest communication, worst blast radius | Same AZ — low latency and no cross-zone egress, still two machines |
| **`podAntiAffinity`** | **One replica per node** | **One replica per zone** — survives losing an entire AZ |

Same `labelSelector`, same effect type. Only `topologyKey` changed.

### 4.2 Two constraints on what you can put there

> - For Pod affinity and anti-affinity, **an empty `topologyKey` field is not allowed** in either form.
> - For **`requiredDuringSchedulingIgnoredDuringExecution` Pod anti-affinity** rules, the admission controller **`LimitPodHardAntiAffinityTopology` limits `topologyKey` to `kubernetes.io/hostname`.** You can modify or disable the admission controller if you want to allow custom topologies.

So a *hard* anti-affinity rule is restricted to per-node spreading by default. An admission controller (chapter 05-01) enforcing a scheduling constraint — the stages keep showing up in each other's topics.

### 4.3 The labelling trap

> Pod anti-affinity **requires nodes to be consistently labeled** — in other words, **every node in the cluster must have an appropriate label matching `topologyKey`**. If some or all nodes are missing the specified `topologyKey` label, **it can lead to unintended behavior**.

A node with no value for the key is in no domain at all, so the rule cannot reason about it.

- **`kubernetes.io/hostname` is always safe** — the kubelet sets it on every node (chapter 05-05).
- **`topology.kubernetes.io/zone` is set by cloud providers** and is usually **absent on a bare-metal or k3s lab cluster**, so a zone-scoped rule there may silently do nothing useful.

```bash
kubectl get nodes -L topology.kubernetes.io/zone -L topology.kubernetes.io/region
```

Check before relying on it.

---

## 5. When scheduling fails

Everything in this chapter produces the same symptom — a `Pending` Pod — and the same diagnostic:

```bash
kubectl get pods -o wide                     # STATUS Pending, NODE <none>
kubectl describe pod <name> | grep -A6 Events
```

The message names which filter rejected each node, and the wording differs by cause:

| Message | Cause |
|---|---|
| `node(s) didn't match Pod's node affinity/selector` | A required **`nodeAffinity`** or `nodeSelector` eliminated the node |
| `node(s) didn't match pod affinity rules` | **Your** required `podAffinity` found no matching Pod in that topology domain |
| `node(s) didn't match pod anti-affinity rules` | **Your** required `podAntiAffinity` found a matching Pod there already |
| `node(s) didn't satisfy existing pods anti-affinity rules` | **Someone else's** Pod has an anti-affinity rule that excludes **you** |
| `node(s) had untolerated taint {...}` | A taint with no matching toleration (chapter 05-06) |
| `Insufficient cpu` / `Insufficient memory` | Resource **requests** exceed what is allocatable |

That fourth message is worth reading twice. **An anti-affinity rule on a Pod that is already running can block a Pod that has no affinity configuration of its own** — your manifest is clean, and the rejection comes from somebody else's.

The count prefix is the quickest read: `0/3 nodes are available:` followed by one clause per reason, each with the number of nodes it accounts for. **If the clauses sum to every node, nothing is feasible and the Pod will wait indefinitely.**

Two more checks worth having to hand:

```bash
kubectl get nodes --show-labels                       # does the label actually exist?
kubectl get pods -o wide -l role=backend              # does the Pod a podAffinity rule wants exist?
kubectl get nodes -L topology.kubernetes.io/zone      # is the topologyKey set on every node?
```

And the behaviour that catches people out: **a `Pending` Pod will schedule itself the moment the situation is fixed, but a `Running` Pod never moves.** `IgnoredDuringExecution` means relabelling a node does nothing to Pods already on it — `kubectl replace --force` or deleting the Pod is what forces a fresh decision.

---

## Exam angle

- **`requiredDuringSchedulingIgnoredDuringExecution` is a HARD rule** — the scheduler cannot place the Pod unless it is met, so **the Pod stays `Pending`** when nothing matches. It acts during **filtering**.
- **`preferredDuringSchedulingIgnoredDuringExecution` is a SOFT rule** — the scheduler **tries**, but **still schedules the Pod elsewhere** if nothing matches. It acts during **scoring**. **`required` = mandatory, `preferred` = best effort.**
- **Only `preferred` has a `weight` (1-100)**, added to the node's score and combined with the other scoring functions — so **a preferred rule can still lose**.
- **`IgnoredDuringExecution` means label changes after scheduling do NOT evict the Pod.** Contrast with a `NoExecute` taint, which does. **`RequiredDuringExecution` was designed but never implemented.**
- **Node affinity reads NODE labels; pod affinity and anti-affinity read the labels of PODS ALREADY RUNNING.** That is the only real difference between them.
- **In `nodeSelectorTerms`, terms are ORed and expressions within one `matchExpressions` are ANDed.** If both `nodeSelector` and `nodeAffinity` are set, **both must be satisfied**.
- **Operators: `In`, `NotIn`, `Exists`, `DoesNotExist`** everywhere, plus **`Gt` and `Lt` for `nodeAffinity` only**. **There is no `nodeAntiAffinity`** — `NotIn` and `DoesNotExist` express it.
- **`topologyKey` is mandatory for pod affinity and anti-affinity and may never be empty.** It names **a node label key**, and **two nodes are in the same domain when they share that label's value**. `kubernetes.io/hostname` means per-node; `topology.kubernetes.io/zone` means per-AZ.
- **`required` pod anti-affinity is limited to `topologyKey: kubernetes.io/hostname`** by the **`LimitPodHardAntiAffinityTopology`** admission controller.
- **Pod anti-affinity needs every node consistently labelled** with the `topologyKey`, or the behaviour is undefined.
- **Inter-pod affinity and anti-affinity are expensive** — *"not recommended in clusters larger than several hundred nodes."* Node affinity carries no such warning.
- **`podAffinity` co-locates (reduce latency); `podAntiAffinity` separates (spread replicas, remove a single point of failure).**

## References

- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) — node affinity, inter-pod affinity and anti-affinity, `topologyKey`, and the operator table
- [Assign Pods to Nodes using Node Affinity](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/) — the `disktype=ssd` task this lecture follows
- [Well-Known Labels, Annotations and Taints](https://kubernetes.io/docs/reference/labels-annotations-taints/) — `kubernetes.io/hostname`, `topology.kubernetes.io/zone` and `topology.kubernetes.io/region`
- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) — the cheaper modern alternative for spreading
