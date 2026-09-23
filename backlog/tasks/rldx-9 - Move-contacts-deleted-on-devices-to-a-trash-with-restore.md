---
id: RLDX-9
title: Move contacts deleted on devices to a trash with restore
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:14'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add contacts.trashed_at. Scopes: active (not archived, not trashed), archived (not trashed), trashed; visible_to_devices = active.
2. CardDAV DELETE on a visible contact trashes it (204), honoring If-Match; archived or unknown contacts return 404.
3. Web: /trash lists trashed contacts newest first with deletion time; Restore clears trashed_at, returning the contact to the main list or the Archive.
4. The main list and Archive exclude trashed contacts. RLDX-12 search builds on the active scope.
5. Integration tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (89 tests): DELETE 204, then GET 404 and PROPFIND without the href, with getctag increasing; If-Match stale 412; Trash shows deletion time; restore returns the contact to the list and to GET; DELETE on an archived contact is 404. Search does not exist yet; RLDX-12 must exclude trashed contacts (AC 4, search half).
<!-- SECTION:NOTES:END -->
