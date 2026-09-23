---
id: RLDX-1
title: Scaffold Rails 8 app with Hotwire and CI script
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:29'
updated_date: '2026-09-23 04:44'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Generate rails new in a scratch dir (Rails 8.1.3, importmap, propshaft, Solid trio, no Kamal) and copy it into the repo without overwriting existing files.
2. Point production SQLite databases at storage/ (the Fly volume mount).
3. Add a placeholder root page with a test that asserts Turbo and Stimulus load through the importmap.
4. Use the Rails 8.1 bin/ci (config/ci.rb) and a single GitHub Actions job that runs it on every pull_request event with no branch filter.
5. Update README; probe a two-layer gh stack and close it.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rails 8.1.3 has no built-in passkey support (checked actionpack/activerecord/railties sources), so RLDX-2 uses the webauthn gem.
Verified bin/ci exits 1 with a RuboCop violation and 0 when clean. bin/dev served / with 200 on port 3999.
Stack probe: gh stack submit --auto opened PR #3 (base main) and PR #4 (base test/rldx-1-stack-probe-a) as stack #5; both closed and unstacked.
<!-- SECTION:NOTES:END -->
