---
id: RLDX-15
title: Support sync-collection sync tokens for CardDAV
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:17'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. sync_changes table (address_book, resource_name, removed); the row id is the sync token (http://rolodex.app/ns/sync/<id>). A migration backfills one row per visible contact.
2. Contact callbacks log changes from the device's point of view: create or vCard edit while visible = changed; visible to hidden (archive, trash) = removed; hidden to visible (unarchive, restore) = added; destroying a visible contact = removed; edits to hidden contacts log nothing.
3. AddressBook#changes_since(token) collapses the log to the last state per resource, bounded by the latest id captured once, and returns the next token. Unparseable or future tokens return nil.
4. REPORT sync-collection: blank token = every member; else changed members with requested props and removed ones as 404 responses; DAV:sync-token at the end. Unknown token = 403 DAV:valid-sync-token.
5. Advertise DAV:sync-collection in supported-report-set and DAV:sync-token on the address book.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (103 tests). Covered: full sync with a blank token; delta after edit and create; archive and trash reported as 404; unarchive and restore reported as additions; device DELETE reported; edit then archive reported once as removed; edits to archived contacts not reported; garbage and future tokens get 403 valid-sync-token; other users' changes are not visible.
AC 5 (Apple clients keep syncing) waits on device testing.
<!-- SECTION:NOTES:END -->
