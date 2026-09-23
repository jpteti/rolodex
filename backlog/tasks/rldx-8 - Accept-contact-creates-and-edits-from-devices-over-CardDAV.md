---
id: RLDX-8
title: Accept contact creates and edits from devices over CardDAV
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
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
- [x] #1 PUT with If-None-Match: * creates a contact, returns 201 and an ETag, and the contact appears in the web UI
- [x] #2 PUT with a matching If-Match updates the contact; a stale ETag returns 412 and changes nothing
- [x] #3 Unknown vCard properties sent by the device survive a later GET byte-for-byte in value
- [x] #4 Extracted columns update from the new vCard on every write
- [x] #5 Malformed vCards return 400 or 415 and store nothing
- [ ] #6 Contacts created and edited on an iPhone and a Mac show up correctly in the web UI
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. PUT on /dav/addressbooks/<user>/contacts/<name>: If-None-Match: * fails with 412 when the resource exists; If-Match must equal the current ETag (412 otherwise, including a missing resource).
2. Accept text/vcard, text/x-vcard, text/directory, or no type (else 415); reject bodies over 5 MB (413).
3. Contact.store_from_device parses the card (400 on parse errors or invalid UTF-8), keeps the body byte for byte, re-extracts columns, and uses the vCard UID (else the existing UID or the resource name).
4. A UID held by another contact returns 409 with CARDDAV:no-uid-conflict naming it.
5. Return 201 + ETag on create and 204 + ETag on update; advertise write, write-content, bind, and unbind privileges.
6. Request tests with a realistic iPhone vCard; device check after deploy.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (82 tests): create 201 + ETag and shown in the web list; GET returns the iPhone vCard byte for byte, including X-SOCIALPROFILE and a custom property with a quoted parameter; If-Match update re-extracts organization and email; stale If-Match 412 with no change; malformed or non-UTF-8 400; JSON 415; duplicate UID 409.
AC 6 (iPhone and Mac edits) waits on the deploy.
<!-- SECTION:NOTES:END -->
