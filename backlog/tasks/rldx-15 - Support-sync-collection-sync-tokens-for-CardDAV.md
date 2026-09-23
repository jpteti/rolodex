---
id: RLDX-15
title: Support sync-collection sync tokens for CardDAV
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - carddav
  - stack-lifecycle
milestone: m-1
dependencies:
  - RLDX-7
  - RLDX-8
  - RLDX-9
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
With only getctag, Apple clients re-list the whole address book on every change. The sync-collection REPORT (RFC 6578) returns only what changed since a sync token. This requires a change log that records archive, unarchive, trash, restore, and permanent delete as additions or removals from the device's point of view.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The address book advertises sync-collection and a DAV:sync-token
- [ ] #2 sync-collection with a token returns only changed contacts, and removed contacts as 404 entries
- [ ] #3 Archiving or trashing a contact reports it as removed; unarchiving or restoring reports it as added
- [ ] #4 An unknown or expired token returns the RFC 6578 valid-sync-token error so clients fall back to a full sync
- [ ] #5 Apple clients keep syncing correctly with sync tokens enabled
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
