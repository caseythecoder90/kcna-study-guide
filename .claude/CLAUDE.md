# Project context for Claude

## What this repo is

KCNA (Kubernetes and Cloud Native Associate) study notes. Study repository only — no application build. The KCNA is one of the five certifications required for CNCF **Kubestronaut** status (KCNA, KCSA, CKA, CKAD, CKS — all active at the same time), which is the end goal behind this repo.

The notes follow James Spurin's Udemy course *"KCNA: Kubernetes and Cloud Native Associate"*, section by section, and are expanded with the mechanics and context that make the facts stick.

**The KCNA is a multiple-choice exam, not a hands-on one.** 60 questions, 90 minutes, online proctored, passing score above 75%. That changes what the notes optimize for compared to the sibling CKAD repo: precise definitions, "which project/component does X", dates, defaults, ports, and clean comparison tables matter more than typing speed. Commands are still recorded (the course is hands-on) but they are supporting material, not the main event.

- Notes live in `notes/`, grouped into **per-section folders** named `NN-<section-slug>/`, one per course section. Each section folder contains its own numbered chapter notes.
- Each section folder has its own `diagrams/` subfolder alongside the notes. Diagrams live with the section that references them — **not** in a single global folder.
- **Diagrams are original PlantUML drawings, never course screenshots.** Each diagram is a `NN-slug.puml` source rendered to `NN-slug.svg` beside it by `tools/diagrams/render.sh`. Lecture screenshots are reference input only — the instructor's slides are not ours to redistribute.
- `tools/diagrams/` holds the shared PlantUML theme (`kcna-theme.puml`) and the render script.
- `notes/exam-facts.md` is the **global recall sheet**: every hard fact worth a multiple-choice question (dates, version numbers, ports, defaults, personas, acronyms). Grows with every chapter.
- `notes/cncf-projects.md` is the **project cheat sheet**: every CNCF project, tool, or standard the course mentions, with its category, maturity level, and a one-line "what it does". Grows with every chapter.
- `notes/commands.md` is the global single-file command reference; `notes/commands/` holds per-topic command files. Same idea as the CKAD repo, lighter weight.
- `README.md` (repo root) is the public landing page. `examples/` holds runnable manifests/Dockerfiles from the hands-on lectures.

### Section folder ↔ course section mapping

| Folder | Course section |
|---|---|
| `notes/01-cloud-native-introduction/` | 1. Course and Cloud Native Introduction |
| `notes/02-cloud-native-architecture/` | 2. Cloud Native Architecture Fundamentals |
| `notes/03-containers-with-docker/` | 3. Containers with Docker |
| `notes/04-kubernetes-fundamentals/` | 4. Kubernetes Fundamentals |
| `notes/05-kubernetes-deep-dive/` | 5. Kubernetes Deep Dive |
| `notes/06-telemetry-and-observability/` | 6. Telemetry and Observability |
| `notes/07-cloud-native-application-delivery/` | 7. Cloud Native Application Delivery |

Course sections 8 (quiz summaries), 9 (product summary cheat sheet), and 10 (credits) have no folder: their content feeds `notes/exam-facts.md` and `notes/cncf-projects.md` instead.

### Notes file layout (the schema)

```
notes/
├── 01-cloud-native-introduction/
│   ├── 01-what-is-cloud-native.md
│   ├── 02-...
│   └── diagrams/
│       ├── 01-is-my-application-cloud-native.puml   # source
│       ├── 01-is-my-application-cloud-native.svg    # rendered, committed
│       └── ...
├── 02-cloud-native-architecture/
│   ├── 01-...
│   └── diagrams/
├── ...
├── commands/
├── commands.md
├── exam-facts.md
├── cncf-projects.md
└── NOTES-WORKFLOW.md
tools/diagrams/
├── kcna-theme.puml        # shared skinparams — every diagram !includes it
└── render.sh              # renders notes/**/diagrams/*.puml → .svg
```

**Rules for new notes (apply this when generating chapters):**
- A new chapter goes in its section folder (`NN-<section>/CC-<chapter-slug>.md`). **Chapter numbers reset at each section** — every section's notes start at `01-...` (or `00-...` for an intro/setup file). Do *not* continue the numbering from the previous section.
- Diagrams referenced by a chapter go in that same section's `diagrams/` subfolder. Diagram numbers run continuously **within a section** and reset per section — `02-cloud-native-architecture/diagrams/` starts at `01-...` independently of `01-cloud-native-introduction/diagrams/`.
- Image references in markdown use **relative paths from the notes file**: `![Caption](./diagrams/NN-name.svg)`. Never use `../diagrams/...` and never hard-code repo-rooted paths (e.g. `notes/...`) in image links.
- **Diagrams must be embedded in the body to render.** A `companion_diagrams:` list in YAML frontmatter is metadata only and does **not** display the image. Every diagram a chapter references must appear in the body as `![Caption](./diagrams/NN-name.svg)`, placed in the relevant section.
- One topic per file. Don't bundle multiple course lectures into one markdown file unless they are genuinely one topic split across short videos.

### Diagram workflow (PlantUML → SVG)

1. Write `notes/<section>/diagrams/NN-slug.puml`. First line after `@startuml` is always `!include ../../../tools/diagrams/kcna-theme.puml` — it pins the Smetana layout engine (no Graphviz needed) and the palette.
2. Render: `tools/diagrams/render.sh notes/<section>/diagrams/NN-slug.puml` (or no args for everything). Commit **both** the `.puml` and the `.svg`.
3. **Verify visually before committing.** Render a PNG to the scratchpad (`java -jar ~/.cache/plantuml/plantuml.jar -tpng -o <scratchpad> file.puml`) and Read it. Check for text overflowing boxes, notes drifting sideways, and unreadable arrow crossings. Re-layout and re-render until clean.
4. Design rules that have worked:
   - Redraw the *concept*, not the slide. Use the course's structure as input; layout, wording, and grouping are ours.
   - `left to right direction` for flows and timelines; default top-to-bottom for hierarchies and side-by-side comparisons.
   - Group with `rectangle "Title" <<group>> { ... }` (`<<groupGood>>` green / `<<groupBad>>` red for contrast). Stack items inside a group with `-[hidden]down->` links; place groups side by side with `-[hidden]right->`.
   - Captions go inside the group as a `label` (hidden-linked below the last item). `note bottom of X` tends to float to the side — avoid it.
   - Emphasis stereotypes: `<<good>>`, `<<bad>>`, `<<accent>>` (filled blue), `<<muted>>`, `<<plain>>`. Red arrows (`-[#DC2626]->`) for tight coupling / problems, green (`-[#16A34A]->`) for the cloud native alternative.
   - Sub-text inside a box: `Main line\n<size:11>detail · detail</size>`.
   - Earn the diagram: hierarchies, flows, before/after, comparisons. Tables of values are markdown, not images.

---

## Commit & PR workflow (required for every change)

Every change — even a small notes edit — goes through this flow. Don't commit directly to `main`.

1. **Open a GitHub issue** describing what's being added or changed.
   ```bash
   gh issue create --title "Add notes for <topic>" --body "Covers <what>. Includes diagrams <N>-<M>."
   ```
   Capture the issue number from the output.

2. **Create a feature branch** off `main`:
   ```bash
   git switch -c notes/<chapter-slug>      # for new chapter notes
   git switch -c docs/<short-slug>         # for recall sheets, commands, or meta docs
   git switch -c fix/<short-slug>          # for corrections
   ```

3. **Commit** on the branch with a clear, conventional message:
   ```bash
   git add <files>
   git commit -m "Add <topic> notes (section NN, chapter CC)"
   ```
   No emojis. No co-author trailer unless explicitly asked. One concise subject line; longer body only if the change needs explanation.

4. **Push the branch** to `origin`:
   ```bash
   git push -u origin HEAD
   ```

5. **Open a PR** with `gh pr create`. The PR body **must** include a GitHub auto-close keyword referencing the issue, so merging the PR closes the issue automatically:
   ```bash
   gh pr create --title "Add <topic> notes" --body "$(cat <<'EOT'
   ## Summary
   - <what changed>

   Closes #<issue-number>
   EOT
   )"
   ```
   Auto-close keywords (any works, case-insensitive): `Closes #N`, `Fixes #N`, `Resolves #N`.

6. **Merge the PR** (`gh pr merge --squash --delete-branch` is the default). The linked issue closes automatically when the merge reaches `main`.

### Quick sanity check before merging
- Issue linked in PR body via `Closes #N`? ✓
- Branch is feature branch, not `main`? ✓
- Commit message is informative (no "wip", no "update")? ✓
- `exam-facts.md` and `cncf-projects.md` updated for anything new the chapter introduced? ✓

---

## Recall sheets — keep them in sync with every chapter

The multiple-choice format rewards two things: recognizing the right term and recalling the right number. Two files carry that load, and **every chapter PR updates them** in the same commit so they never drift:

- **`notes/exam-facts.md`** — one line per fact, grouped by section. Dates (Kubernetes open-sourced 2014), version thresholds (dockershim removed in 1.24), ports (etcd 2379/2380), defaults, personas, acronym expansions, "X was the first Y". If a fact could be the answer to a "which of the following" question, it goes here.
- **`notes/cncf-projects.md`** — one row per project/tool/standard: name, category (orchestration, runtime, observability, service mesh, delivery, ...), CNCF maturity (Sandbox / Incubating / Graduated / not a CNCF project), one-line purpose, and the chapter that introduced it.

When a chapter mentions a project or standard that is not yet in `cncf-projects.md`, add it. When it states a number, date, or default, add it to `exam-facts.md`.

## Commands documentation rules

When a chapter includes hands-on `docker`/`kubectl`/shell commands:

- Add them to **`notes/commands.md`** under the relevant section.
- Add them to the matching per-topic file in **`notes/commands/`** (create it and add it to `commands/README.md` if none exists).

Commands are supporting material for the KCNA — record what the course demonstrates, don't drill for speed. There is no imperative-generator requirement here as there was for CKAD.

---

## Style

- No emojis in notes or commit messages unless the user explicitly asks for them.
- Concise, exam-focused phrasing. No marketing fluff, no padding.
- **Lean notes — no scaffolding.** Do NOT add "Why this is in KCNA" preambles, "Key takeaways"/"TL;DR" summaries, "Open threads" checklists, instructor narration, or personal anecdotes. Keep the definitions, comparison tables, diagrams, commands, and the exam-relevant "why".
- **Definitions are load-bearing.** The exam asks for the precise phrasing of concepts (what is cloud native, what is a service mesh, what does the scheduler do). Give the canonical definition first, then explain it. Where the CNCF or kubernetes.io has an official definition, use its wording and link it.
- **Comparison tables over prose** for anything the exam can contrast: Docker vs containerd, ReplicaSet vs Deployment, logs vs metrics vs traces, CKA vs CKAD vs KCNA scope.
- **`## Exam angle` closes every chapter** (before References): 3-6 bullets on what a multiple-choice question about this topic looks like and the distractor to avoid. This is the KCNA equivalent of the CKAD "exam-pattern gotchas" — keep it tight, no quiz scaffolding.
- **References section.** Each chapter ends with a `## References` section of 2-4 canonical, verified links. Acceptable sources: `kubernetes.io`, `cncf.io`, `github.com/cncf/*`, `docs.docker.com`, `opencontainers.org`, `landscape.cncf.io`, `prometheus.io`, `opentelemetry.io`, and the official site of any project discussed. Verify URLs before adding them — never guess a doc URL.
- Diagrams referenced by their numbered filename prefix from the **section's own** `diagrams/` subfolder, via `./diagrams/<NN-name>.svg`.
- Prefer editing existing files over creating new ones; keep new files focused (one topic per file).
