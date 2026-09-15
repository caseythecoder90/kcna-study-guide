# Notes workflow — turning lectures into chapters

How chapters in this repo get written. Same mechanics as the CKAD repo, with the KCNA-specific additions (recall sheets, `## Exam angle`) and one hard rule on diagrams.

## Diagrams are ours, not the course's

Lecture screenshots are **input**: they tell us which concepts the lecture emphasized and how it structured them. They are never committed. Every diagram in `diagrams/` is an original PlantUML drawing (`NN-slug.puml`) rendered to SVG (`NN-slug.svg`) with the shared theme in `tools/diagrams/`. Redraw the concept, not the slide.

```bash
tools/diagrams/render.sh                                   # render everything
tools/diagrams/render.sh notes/<section>/diagrams/NN-x.puml # render one
```

Commit both the `.puml` and the `.svg`. Preview by rendering a PNG into the scratchpad and looking at it before committing — text overflow and drifting notes are the usual failures.

## The one rule that makes images actually show up

Listing a diagram in YAML frontmatter (`companion_diagrams:`) is **metadata only — it never renders**. An image appears in the notes only if it is embedded in the body with a relative path:

```markdown
![Short caption](./diagrams/03-cncf-formation-timeline.svg)
```

Always `./diagrams/...` — never `../diagrams/...`, never repo-rooted paths like `notes/...`.

## Numbering rules

- Chapter files: `<CC>-<chapter-slug>.md`, one topic per file. Chapter numbers reset to `01` (or `00` for intro/setup) at the start of each section folder.
- Diagrams: `<NN>-<diagram-slug>.puml` + `.svg` in the section's own `diagrams/` subfolder. Diagram numbers run continuously **within a section** — they do NOT reset per chapter, only per section.
- To resume: look in the section folder for the highest existing `CC-` file and the highest `NN-` in `diagrams/`, then add 1 to each.

## Which slides earn a diagram

Only concepts that carry structure a table or sentence can't: two-column checklists, timelines, architecture layouts, before/after comparisons, coupling relationships. Plain text banners ("Containers != Cloud Native", a definition on a blue background) go into prose.

## Per-chapter checklist

1. Chapter file in the right section folder with the next `CC-` number.
2. Diagrams written as `.puml`, rendered with `tools/diagrams/render.sh`, previewed, and embedded in the body with `./diagrams/NN-slug.svg`.
3. Definitions first, comparison tables where the exam can contrast two things.
4. `## Exam angle` — 3-6 bullets on what the question looks like and the distractor to avoid.
5. `## References` — 2-4 verified links.
6. New facts (dates, versions, ports, defaults, personas) added to `exam-facts.md` under the section heading.
7. New projects/tools/standards added to `cncf-projects.md` with category and maturity.
8. Any hands-on commands added to `commands.md` and the per-topic file in `commands/`.

---

## Section-start prompt

> You are helping me build KCNA study notes from lecture screenshots I upload. Read `.claude/CLAUDE.md` in this repo and follow its rules exactly — in particular, draw original PlantUML diagrams (rendered to SVG via `tools/diagrams/render.sh`, previewed before committing) instead of reusing my screenshots.
>
> For this section: section folder = `<fill in>`, start chapter numbering at `<CC>`, start diagram numbering at `<NN>`. First lecture: `<topic>`.
>
> Confirm the folder and the starting numbers back to me, then wait for my first lecture's screenshots. For every chapter, also update `notes/exam-facts.md` and `notes/cncf-projects.md`.

## Mid-section continuation prompt

> Continuing KCNA notes for section `<SECTION-FOLDER>`. Same rules as `.claude/CLAUDE.md`: one topic per file, `<CC>-<slug>.md`; original PlantUML diagrams in `./diagrams/<NN>-<slug>.puml` rendered to `.svg`, previewed, and ALWAYS embedded in the body; definitions first, `## Exam angle` then `## References`; update `exam-facts.md` and `cncf-projects.md`. Resume at chapter `<CC>` and diagram `<NN>`. Here are the next screenshots.

---

## Diagram conventions

- **Tool:** PlantUML (`~/.cache/plantuml/plantuml.jar`, Java) with the built-in Smetana layout engine — no Graphviz install needed. Output SVG.
- **Theme:** every `.puml` starts with `!include ../../../tools/diagrams/kcna-theme.puml`. Light background, Arial, Kubernetes blue `#326CE5` primary, red `#DC2626` for problems/tight coupling, green `#16A34A` for the cloud native alternative, amber notes.
- **Stereotypes available:** `<<group>>` / `<<groupGood>>` / `<<groupBad>>` for containers; `<<good>>` / `<<bad>>` / `<<accent>>` / `<<muted>>` / `<<plain>>` for boxes.
- **Layout tricks:** `-[hidden]down->` to stack items inside a group, `-[hidden]right->` to put groups side by side, `label` for captions inside a group, `left to right direction` for timelines/flows, `\n<size:11>...</size>` for sub-text in a box.
- **Earn the diagram:** hierarchies, flows over time, before/after, conceptual mappings. Tables of values are markdown, not images.
