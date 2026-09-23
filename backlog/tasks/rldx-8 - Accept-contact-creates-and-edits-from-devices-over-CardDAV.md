---
id: RLDX-8
title: Accept contact creates and edits from devices over CardDAV
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - carddav
  - stack-lifecycle
milestone: m-1
dependencies:
  - RLDX-6
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Once devices sync, users will add and edit contacts on their phone. CardDAV writes use PUT with conditional headers. Apple clients choose their own resource names (usually a UUID.vcf). The stored raw vCard must keep every property the device sends, including ones the web UI does not display.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 PUT with If-None-Match: * creates a contact, returns 201 and an ETag, and the contact appears in the web UI
- [ ] #2 PUT with a matching If-Match updates the contact; a stale ETag returns 412 and changes nothing
- [ ] #3 Unknown vCard properties sent by the device survive a later GET byte-for-byte in value
- [ ] #4 Extracted columns update from the new vCard on every write
- [ ] #5 Malformed vCards return 400 or 415 and store nothing
- [ ] #6 Contacts created and edited on an iPhone and a Mac show up correctly in the web UI
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
