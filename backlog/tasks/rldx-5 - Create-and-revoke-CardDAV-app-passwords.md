---
id: RLDX-5
title: Create and revoke CardDAV app passwords
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - auth
  - web
  - carddav
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-2
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple Contacts authenticates CardDAV accounts with a username and password over HTTP Basic auth and cannot use passkeys. Decision: per-device app passwords, created in the web UI, each revocable, stored hashed. The same pattern iCloud and Fastmail use. The CardDAV endpoint accepts only app passwords; the web UI accepts only passkeys.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A signed-in user can create a named app password (for example iPhone) and sees the generated secret exactly once
- [ ] #2 The app password list shows name, creation time, and last-used time, never the secret
- [ ] #3 Revoking an app password makes the next CardDAV request with it return 401
- [ ] #4 Secrets are stored hashed, and Basic auth compares them in constant time
- [ ] #5 Basic auth requests over plain HTTP are refused in production
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
