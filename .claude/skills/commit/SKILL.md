---
name: commit
description: Use whenever the user asks to commit changes (e.g. "commit this", "commit the current step", "/commit"). Reviews the diff and commits with a Conventional Commits message.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

## Context

- Current branch: !`git branch --show-current`
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Recent commits: !`git log --oneline -10`

## Rules

- If on a protected branch (`main`, `master`, or similar), refuse and
  explain why — commit on a feature branch instead.
- Never stage files containing credentials or secrets (`.env`, API keys,
  cloud credentials, connection configs with tokens). If the diff touches
  these, stop and flag them instead of committing.
- If the diff contains merge conflict markers (`<<<<<<<`, `=======`,
  `>>>>>>>`), stop and flag instead of committing.
- Don't blindly stage everything untracked — check `.gitignore` and be
  cautious of build artifacts, caches, dependency folders, and large/binary
  or data files that don't look intentional.
- Never `git push`. Never `git commit --amend`. Only if explicitly asked.

## Grouping changes into commits

Group the changes into **separate commits by type**, one commit per type.
Stage only the files belonging to a type, commit, then move to the next.
Commit the types in this order of priority (skip any type with no changes):

1. **planing** — planning and design notes, roadmaps, `.scratchpad/`
   planning material, task/issue write-ups, anything that describes *what to
   do* rather than doing it.
2. **infra** — build and tooling: `Dockerfile`, `.dockerignore`, `.github/`
   CI, `DESCRIPTION`/`renv.lock` dependencies, `.Rbuildignore`, `.gitignore`,
   config scaffolding.
3. **code** — package source and behavior: `R/`, `inst/sql/`,
   `inst/plumber/`, `inst/reports/`, and other functional code.
4. **test** — tests: `tests/` and test fixtures/data.
5. **docu** — documentation: `README.md`, `NEWS.md`, `vignettes/`,
   `development/*.md`, `CLAUDE.md`, generated `man/`, and other docs.

If a single file legitimately spans two types, place it under the
higher-priority type. If the split is ambiguous, ask before committing.

## Commit message format

Conventional Commits with scope: `type(scope): summary`, where **type** is
one of the five above (`planing`, `infra`, `code`, `test`, `docu`).

- **scope** — the affected part of the codebase, inferred from changed
  paths. Omit if the change spans the whole project.
- **summary** — imperative mood, lowercase, no trailing period, based on
  the actual diff. Full line under 72 characters.

```
planing(hll): outline sketch-merge rollout steps
infra(docker): pin renv during image build
code(api): correct age calculation in report
test(counts): cover unmapped source concepts
docu(readme): update setup instructions
```

**Body (optional):** add one when the *why* isn't obvious from the diff —
cause of a bug, a tradeoff, an issue closed. Skip for small,
self-explanatory changes. Blank line after the subject, then free text
wrapped at ~72 chars; bullets are fine.

```
fix(api): correct age calculation in report

Off-by-one in the boundary check dropped the last bucket's records.

Fixes #58
```

## After committing

Once all commits are made, show the user a summary list of every commit
created this run, most recent last, one line each: short hash and commit
subject (first line of the message only). No other commentary.

```
- `<hash>` <subject line>
```

## Your task

Based on the context above, group the changes by type and create one commit
per type, in the priority order above (planing, infra, code, test, docu),
staging only that type's files for each. If a rule blocks a commit, stop and
explain why. Otherwise, stage and commit each type in turn — no commentary
during this — then finish with the summary list described above.