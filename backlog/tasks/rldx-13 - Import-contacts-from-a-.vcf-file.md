---
id: RLDX-13
title: Import contacts from a .vcf file
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
labels:
  - web
  - stack-web
milestone: m-1
dependencies:
  - RLDX-4
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
iOS does not copy existing iCloud contacts into a newly added CardDAV account, so the practical migration path is exporting all contacts from macOS Contacts as one .vcf and uploading it. Exported files hold many vCards, may include embedded photos, and can be large.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Uploading a multi-contact .vcf creates one contact per vCard, keeping each raw vCard
- [x] #2 A vCard whose UID matches an existing contact updates that contact instead of duplicating it
- [x] #3 vCards without a UID get a generated one
- [x] #4 The result page reports counts of created, updated, and failed cards, with a reason per failure
- [ ] #5 A full export from macOS Contacts imports without timing out the request (use a background job if needed)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Import model (filename, raw source, status, created/updated counts, JSON failures) and ImportJob; the upload request stores the file and enqueues the job, so large exports never block the request.
2. Vcard.split walks raw lines so each card keeps its original folding (BEGIN/END lines are never folded), normalized to CRLF.
3. Per card: a matching UID updates that contact; otherwise create one with resource name <UID>.vcf (or a UUID when the UID is not path-safe); a missing UID gets a generated one written into the card. Parse errors and invalid UTF-8 are recorded per card with a reason.
4. /imports/:id shows status and counts and refreshes every 2 seconds until the import finishes; the source is cleared when done.
5. Integration tests, plus a timing run on a large synthetic export.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Timing (local, rails runner): 2000 cards with 20 KB photos each (55.9 MB) imported in 34.7 s in the job, 0 failures. The request itself only stores the file and enqueues the job.
Verified with bin/ci (137 tests): 5-card file gives created 3 / updated 1 / failed 1 with the reason; the Curie card is stored byte for byte, including the folded PHOTO; the UID match updates instead of duplicating; the no-UID card gets a generated UID inside its vCard; re-importing updates.
Also removed two empty generated model test stubs.
<!-- SECTION:NOTES:END -->
