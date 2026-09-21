---
name: pull-request
description: Use whenever the user asks to open/create a pull request (e.g. "open a PR", "create a PR for this", "/pr"). Commits any pending changes, runs devtools::check(), and opens a PR against development.
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(Rscript:*), Read, Edit
---

## Context

- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git status -sb`
- Commits not yet in development: !`git log development..HEAD --oneline 2>/dev/null`
- Existing PR for this branch, if any: !`gh pr list --head "$(git branch --show-current)" --json number,url,title 2>/dev/null`

## Rules

- **Base branch is always `development`.** Never open a PR against `main`.
- **Refuse if the current branch is `main` or `development`** — a PR is
  opened from a feature branch, not while sitting on `development` itself.
- **Uncommitted changes present** → commit them first, following the
  `commit` skill's rules exactly. Do not open the PR until this is done.
- **A PR already exists for this branch** → don't create a duplicate.
  Report the existing PR's URL instead, and ask if they want to update its
  description.
- **Run `devtools::check()` before opening.**
  - If there are test **errors/failures** → stop, do not open the PR, and
    report the failures to the user so they can be fixed.
  - If the only issues are **documentation or reference problems**
    (Roxygen/Rd warnings, missing `@param`/`@return`, broken cross-refs,
    undocumented arguments, etc.) → fix them directly, re-run the check to
    confirm it's clean, then just inform the user what was fixed. Don't
    stop for these.
  - If check is fully clean, proceed silently on this point.
- **Push only the current feature branch.** Never push to or force-push
  over `main`/`development`.
- **Never merge.** This skill only opens the PR — merging is a human step.

## PR content

- **Title**: short summary of the change (Conventional-Commits style,
  matching the repo's commit convention).
- **Body**, using this shape:
  ```markdown
  ## Summary
  Derived from the commit messages not yet in development (listed above)
  — summarize what they collectively do, don't just restate the list.

  ## Changes
  - One bullet per commit not yet in development, in plain language.

  ## Testing
  Result of `devtools::check()` — clean, or what was auto-fixed.

  Fixes #<issue-number>
  ```
- Infer the issue number from the branch name (e.g. `feature/42-fix-thing`
  → `#42`) or a commit trailer. Omit the `Fixes #` line if neither is
  present — don't guess a number.
- Default to a ready (non-draft) PR unless a commit message contains `WIP`,
  in which case ask first.

## Your task

Check the context above against the rules, in order: branch check →
commit pending changes if needed → devtools::check() → existing-PR check.
If anything blocks opening (protected branch, failing tests, existing PR),
stop and explain. Otherwise, push the branch and open the PR using the
content shape above, then report the PR URL.