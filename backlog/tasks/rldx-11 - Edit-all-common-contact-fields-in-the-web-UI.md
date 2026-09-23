---
id: RLDX-11
title: Edit all common contact fields in the web UI
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:22'
labels:
  - web
  - stack-editing
milestone: m-1
dependencies:
  - RLDX-4
  - RLDX-9
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first web form covers only name, organization, emails, and phones. Editing on the web should cover the fields people use in Apple Contacts, while leaving untouched every vCard property the form does not show (the raw vCard is the source of truth). Deleting from the web moves the contact to the Trash, matching device deletes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The form edits name parts, nickname, organization, job title, multiple labeled emails, phones, postal addresses, URLs, birthday, and notes
- [ ] #2 Adding and removing repeated fields (emails, phones, addresses) works without a full page reload (Turbo/Stimulus)
- [ ] #3 Saving preserves every vCard property the form does not display
- [ ] #4 Apple custom labels (X-ABLabel) display and round-trip
- [ ] #5 Delete in the web UI moves the contact to the Trash
- [ ] #6 Edits appear on devices after their next refresh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Vcard::Label reads and writes Apple labels: standard labels as TYPE values (mobile=CELL, home fax=HOME+FAX, ...), built-ins (other, homepage) and custom text as X-ABLabel in the property's item group.
2. ContactEditor loads the form from the vCard (name parts, nickname, organization, job title, labeled emails/phones/addresses/URLs, birthday, note). On save it compares each field to its loaded value and rewrites only changed properties, keeping params, groups, extra N/ORG/ADR components, and property order. Removed rows drop their helper properties (X-ABLabel, X-ABADR). An unchanged form returns the original text byte for byte.
3. Birthdays: YYYY-MM-DD, or MM-DD written the Apple way (1604 + X-APPLE-OMIT-YEAR).
4. ContactsController new/create/edit/update use the editor; destroy moves the contact to the Trash.
5. A Stimulus rows controller adds rows from a <template> and removes them in place; new rows get numeric indexes so Rails parses them as an array.
6. Model tests for the editor; system tests for add/remove rows and web delete.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
System test caught a bug: non-numeric row indexes (new123) are dropped by params.expect, so new rows use numeric indexes.
Verified with bin/ci (117 tests + 5 system tests): untouched save returns identical bytes; a title edit changes only TITLE; custom label Work cell and standard mobile round-trip; removing an address drops item3.X-ABADR; the system test added an email and an address and removed a phone with the page marker intact (no reload); web Delete moves the contact to the Trash. Edits change the ETag and ctag, which drive device refresh (AC 6 device check waits on deploy).
<!-- SECTION:NOTES:END -->
