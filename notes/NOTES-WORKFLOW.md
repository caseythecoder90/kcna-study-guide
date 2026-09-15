# Notes workflow — turning lecture screenshots into chapters

How chapters in this repo get written. Same mechanics as the CKAD repo, with the KCNA-specific additions (recall sheets, `## Exam angle`) baked in.

## The one rule that makes images actually show up

Listing a diagram in YAML frontmatter (`companion_diagrams:`) is **metadata only — it never renders**. An image appears in the notes only if it is embedded in the body with a relative path:

```markdown
![Short caption](./diagrams/03-cncf-formation-timeline.png)
```

Always `./diagrams/...` — never `../diagrams/...`, never repo-rooted paths like `notes/...`.

## Numbering rules

- Chapter files: `<CC>-<chapter-slug>.md`, one topic per file. Chapter numbers reset to `01` (or `00` for intro/setup) at the start of each section folder.
- Diagrams: `<NN>-<diagram-slug>.png` in the section's own `diagrams/` subfolder. Diagram numbers run continuously **within a section** — they do NOT reset per chapter, only per section.
- To resume: look in the section folder for the highest existing `CC-` file and the highest `NN-` in `diagrams/`, then add 1 to each.

## Which screenshots become diagrams

Only slides that carry structure a table or sentence can't: checklists with two columns of meaning, timelines, architecture pictures, before/after comparisons. Plain text banners ("Containers != Cloud Native", a definition on a blue background) go into prose, not `diagrams/`.

## Per-chapter checklist

1. Chapter file in the right section folder with the next `CC-` number.
2. Every diagram embedded in the body with `./diagrams/NN-slug.png`.
3. Definitions first, comparison tables where the exam can contrast two things.
4. `## Exam angle` — 3-6 bullets on what the question looks like and the distractor to avoid.
5. `## References` — 2-4 verified links.
6. New facts (dates, versions, ports, defaults, personas) added to `exam-facts.md` under the section heading.
7. New projects/tools/standards added to `cncf-projects.md` with category and maturity.
8. Any hands-on commands added to `commands.md` and the per-topic file in `commands/`.
9. Image save list in the reply: `NN-slug.png` plus which screenshot to save as it.

---

## Section-start prompt

> You are helping me build KCNA study notes from lecture screenshots I upload. Read `.claude/CLAUDE.md` in this repo and follow its rules exactly.
>
> For this section: section folder = `<fill in>`, start chapter numbering at `<CC>`, start diagram numbering at `<NN>`. First lecture: `<topic>`.
>
> Confirm the folder and the starting numbers back to me, then wait for my first lecture's screenshots. For every chapter, also update `notes/exam-facts.md` and `notes/cncf-projects.md`, and end your reply with the image save list.

## Mid-section continuation prompt

> Continuing KCNA notes for section `<SECTION-FOLDER>`. Same rules as `.claude/CLAUDE.md`: one topic per file, `<CC>-<slug>.md`; diagrams in `./diagrams/<NN>-<slug>.png` and ALWAYS embedded in the body; definitions first, `## Exam angle` then `## References`; update `exam-facts.md` and `cncf-projects.md`. Resume at chapter `<CC>` and diagram `<NN>`. Here are the next screenshots.

---

## Diagram conventions (for generated diagrams, not screenshots)

Most diagrams here are course screenshots saved under the numbered filename. When a concept needs a diagram the course doesn't provide:

- **Format:** PNG, ~1600-1800px wide.
- **Tool:** matplotlib (preferred) or raw SVG rendered to PNG.
- **Palette:** dark background `#0d1b2a`, accent magenta `#ff2e93` for titles, text `#e6e6e6`, panels `#16263a`, code/yellow `#ffd166`, notes/cyan `#7fd1ff`, success/green `#3fbf5f`, warn/red `#ff4d4d`, purple accent `#7a5cff`.
- **Earn the diagram:** hierarchies, flows over time, before/after, conceptual mappings. Tables of values are markdown, not images.
- **Verify visually** after rendering: no overflow, no overlap.
