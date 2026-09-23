---
id: doc-1
title: Branch and PR workflow
type: guide
created_date: '2026-09-23 04:32'
updated_date: '2026-09-23 04:32'
tags:
  - workflow
  - git
---
# Branch and PR workflow

Rolodex lands all work through pull requests on github.com/jpteti/rolodex, targeting `main`. Use GitHub stacked PRs (the `gh stack` CLI extension) when a task builds on work that has not merged yet, or when one task is too large to review as one diff.

## Rules

- Open at least one PR per Backlog task. Put the task ID first in each branch name and PR title, for example `skeleton/rldx-2-passkey-sign-in` and "RLDX-2: Sign in with a passkey".
- Start a task as soon as its dependencies have open PRs. Branch it on top of the dependency's branch with `gh stack add` instead of waiting for the merge.
- Keep each stack linear and on one topic. Start a separate stack from `main` for work that does not depend on unmerged code.
- When a stack needs a task whose dependencies sit in a different, unmerged stack, wait for those dependencies to merge, then start the new stack from `main`.
- Split a task into several stack layers when its diff covers more than one concern. Plan the layers before writing code. Name each layer `<topic>/rldx-N-<concern>`.
- Merge bottom-up with `gh stack merge <pr> --yes`. Run `gh stack sync --prune` after merges.
- Every PR in a stack must pass `bin/ci` in GitHub Actions, whatever its base branch.
- Move a Backlog task to Done only after all of its PRs have merged to `main`.

## Planned stacks

Stack order follows the task dependency graph. Change the plan when dependencies change.

| Stack topic | Layers, bottom to top | Starts from |
|---|---|---|
| `skeleton` | RLDX-1, RLDX-2, RLDX-4, RLDX-5, RLDX-3, RLDX-6 | `main` |
| `lifecycle` | RLDX-7, RLDX-8, RLDX-9, RLDX-10, RLDX-15 | top of `skeleton`, or `main` once RLDX-6 merges |
| `web` | RLDX-12, RLDX-13 | `main` once RLDX-4 merges |
| `editing` | RLDX-11, RLDX-14 | `main` once RLDX-9 merges |
| `groups` | RLDX-16, RLDX-17, RLDX-18 | `main` once RLDX-8 merges |

RLDX-3 (deploy) sits above RLDX-5 so the deployed app includes app passwords before RLDX-6 tests CardDAV on real devices. Deploying RLDX-3 from its branch before it merges is allowed for device testing.

## Tasks likely to need more than one layer

Decide the layers when you pick up the task. These tasks cover several concerns and are the likeliest to split:

- RLDX-6: CardDAV discovery and auth; PROPFIND listings; multiget REPORT and GET.
- RLDX-8: PUT handling and ETag preconditions; vCard parsing and field extraction.
- RLDX-11: the edit form; vCard merging that keeps unknown properties.
- RLDX-15: the change log model; the sync-collection REPORT.
- RLDX-16: group storage; the group web views.
