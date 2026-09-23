---
id: RLDX-13
title: Import contacts from a .vcf file
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
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
- [ ] #1 Uploading a multi-contact .vcf creates one contact per vCard, keeping each raw vCard
- [ ] #2 A vCard whose UID matches an existing contact updates that contact instead of duplicating it
- [ ] #3 vCards without a UID get a generated one
- [ ] #4 The result page reports counts of created, updated, and failed cards, with a reason per failure
- [ ] #5 A full export from macOS Contacts imports without timing out the request (use a background job if needed)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
