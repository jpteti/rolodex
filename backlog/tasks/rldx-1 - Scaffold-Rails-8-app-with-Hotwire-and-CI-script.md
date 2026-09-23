---
id: RLDX-1
title: Scaffold Rails 8 app with Hotwire and CI script
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:29'
updated_date: '2026-09-23 04:40'
labels:
  - infra
  - stack-skeleton
milestone: m-0
dependencies: []
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: chore
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rolodex needs an app to build on. Decisions from the planning interview (2026-09-23): Rails 8 with Hotwire (Turbo + Stimulus), SQLite as the only database (production runs SQLite on a Fly.io volume, see the deploy task), Solid Queue/Cache/Cable, and the Rails default test framework. The app serves both a web UI and a CardDAV endpoint (RFC 6352) for macOS/iOS Contacts. One user today; a second user (sharing with a spouse) may come later, so contacts will belong to a user-owned address book from the start.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 rails new app lives at the repository root and boots with bin/dev
- [ ] #2 SQLite is the database in development, test, and production configs
- [ ] #3 Turbo and Stimulus are installed and a placeholder root page renders
- [ ] #4 bin/ci runs the test suite, RuboCop, and Brakeman, and exits non-zero on any failure
- [ ] #5 README documents setup, running the app, and running bin/ci
- [ ] #6 A GitHub Actions workflow runs bin/ci on every pull request, including PRs whose base is another feature branch
- [ ] #7 Stacked PRs work on jpteti/rolodex: gh stack submit --auto opens a two-layer test stack, which is then closed
- [ ] #8 README documents the stack workflow setup (gh extension install github/gh-stack, git config rerere.enabled true) and links doc-1
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
