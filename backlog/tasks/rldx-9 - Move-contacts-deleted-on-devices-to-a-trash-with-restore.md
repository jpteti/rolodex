---
id: RLDX-9
title: Move contacts deleted on devices to a trash with restore
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - carddav
  - web
  - stack-lifecycle
milestone: m-1
dependencies:
  - RLDX-8
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A stray swipe on a phone should not destroy a contact. Decision: a CardDAV DELETE soft-deletes the contact into a Trash, separate from the Archive. Trashed contacts stay until the user restores or permanently deletes them; nothing expires automatically.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CardDAV DELETE returns 204, removes the contact from all CardDAV responses, and changes getctag
- [ ] #2 The web UI has a Trash section listing trashed contacts with their deletion time
- [ ] #3 Restoring a contact returns it to the main list and to devices on their next refresh
- [ ] #4 Trashed contacts are excluded from the main list and search
- [ ] #5 DELETE on an archived contact is a 404 (devices cannot see archived contacts)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
