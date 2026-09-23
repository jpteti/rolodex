---
id: RLDX-7
title: Archive and unarchive contacts
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:11'
labels:
  - web
  - carddav
  - stack-lifecycle
milestone: m-1
dependencies:
  - RLDX-6
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The core requirement beyond sync: keep contacts the user no longer wants on their phone without losing them. An archived contact disappears from every CardDAV response, so devices remove it, while the web UI keeps it in an Archive section. Archive is distinct from trash (see the trash task): archive is a deliberate keep-but-hide, trash is a pending delete.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A contact detail page has an Archive action; archived contacts leave the main list and appear in an Archive section
- [ ] #2 Archived contacts are absent from PROPFIND listings, multiget, and GET (404), and the address book getctag changes on archive
- [ ] #3 After a device refresh, the archived contact is gone from macOS and iOS Contacts
- [ ] #4 Unarchiving returns the contact to the main list and to devices on their next refresh
- [ ] #5 Archived contacts stay viewable in the web UI with all fields intact
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add contacts.archived_at with archived/unarchived scopes; visible_to_devices = unarchived, so every CardDAV response (PROPFIND, multiget, GET) drops archived contacts.
2. Archive/Unarchive buttons on the contact page (ArchivesController create/destroy); the ctag bumps on the update.
3. The main list shows unarchived contacts; /archive lists archived ones; archived contacts keep their detail page and raw vCard.
4. Integration tests for web and CardDAV behavior; device check after deploy.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (69 tests): archive removes the contact from the main list and adds it to /archive, CardDAV PROPFIND omits it, multiget returns 404, GET returns 404, and getctag increases. Unarchive reverses each. Device checks (AC 3, 4) wait on the deploy.
<!-- SECTION:NOTES:END -->
