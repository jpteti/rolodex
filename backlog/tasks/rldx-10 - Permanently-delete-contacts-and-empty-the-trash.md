---
id: RLDX-10
title: Permanently delete contacts and empty the trash
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - web
  - stack-lifecycle
milestone: m-1
dependencies:
  - RLDX-9
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The trash keeps contacts indefinitely, so the user needs a way to remove them for good. Permanent deletion happens only from the web UI Trash section.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A trashed contact can be permanently deleted after a confirmation step
- [ ] #2 Empty Trash permanently deletes every trashed contact after a confirmation step
- [ ] #3 Permanently deleted contacts are gone from the database and cannot be restored
- [ ] #4 Contacts outside the trash cannot be permanently deleted directly
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
