---
id: RLDX-16
title: Sync Apple Contacts groups over CardDAV
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - carddav
  - web
  - stack-groups
milestone: m-1
dependencies:
  - RLDX-8
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: low
type: feature
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple Contacts stores groups in a CardDAV address book as separate vCards with X-ADDRESSBOOKSERVER-KIND:group and one X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:<contact UID> per member. Groups created on a device should round-trip through Rolodex and be visible on the web.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Group vCards PUT by devices are stored as groups, separate from contacts
- [ ] #2 Groups created or changed on one device appear on the other device
- [ ] #3 Group vCards never appear in the web contact list
- [ ] #4 The web UI lists groups and filters contacts by group
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
