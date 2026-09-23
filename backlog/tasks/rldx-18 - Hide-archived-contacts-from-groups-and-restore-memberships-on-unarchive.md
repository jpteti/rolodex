---
id: RLDX-18
title: Hide archived contacts from groups and restore memberships on unarchive
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - carddav
  - stack-groups
milestone: m-1
dependencies:
  - RLDX-7
  - RLDX-16
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: low
type: feature
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Group vCards list members by UID. If a group still lists an archived contact, devices see a dangling member. Decision: synced group vCards omit archived members, and Rolodex remembers the memberships so unarchiving restores them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Group vCards served over CardDAV omit archived members
- [ ] #2 A device PUT of a group vCard does not drop the stored memberships of archived contacts
- [ ] #3 Unarchiving a contact restores it to every group it belonged to, on the web and on devices
- [ ] #4 The web UI shows an archived contact's remembered groups
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
