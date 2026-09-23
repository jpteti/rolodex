---
id: RLDX-10
title: Permanently delete contacts and empty the trash
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
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
- [x] #1 A trashed contact can be permanently deleted after a confirmation step
- [x] #2 Empty Trash permanently deletes every trashed contact after a confirmation step
- [x] #3 Permanently deleted contacts are gone from the database and cannot be restored
- [x] #4 Contacts outside the trash cannot be permanently deleted directly
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Move Trash actions into TrashedContactsController under /trash: index, POST restore, DELETE destroy (permanent), DELETE empty.
2. Only the trashed scope is loaded, so active or archived contacts 404.
3. Delete and Empty Trash buttons use Turbo confirm dialogs.
4. Integration tests for scope and deletion; a system test that dismisses, then accepts, the confirm dialog.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci: 94 tests + 3 system tests. The system test dismisses the confirm dialog (contact stays) and then accepts it (row gone, database row gone). Empty Trash deletes exactly the trashed contacts. Restore after permanent delete is 404. Active and archived contacts 404 on the permanent-delete route.
<!-- SECTION:NOTES:END -->
