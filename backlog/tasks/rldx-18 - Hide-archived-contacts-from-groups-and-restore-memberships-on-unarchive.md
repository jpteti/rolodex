---
id: RLDX-18
title: Hide archived contacts from groups and restore memberships on unarchive
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
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
- [x] #1 Group vCards served over CardDAV omit archived members
- [x] #2 A device PUT of a group vCard does not drop the stored memberships of archived contacts
- [ ] #3 Unarchiving a contact restores it to every group it belonged to, on the web and on devices
- [x] #4 The web UI shows an archived contact's remembered groups
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Group#served_vcard drops MEMBER lines for contacts that are archived or trashed; group ETags come from the served text, so they change when a member is archived or unarchived.
2. A device PUT of a group re-appends MEMBER lines for hidden members the device could not see, so their memberships stay.
3. When a contact becomes hidden or visible again, log a sync change for every group that lists it, so devices refetch those groups.
4. The contact page shows an archived contact's remembered groups with a note that unarchiving restores them.
5. Integration tests covering CardDAV GET, multiget, PUT, sync-collection, and the web.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (157 tests): after archive, Family serves only Grace and Work serves no members; ETags change; sync lists the contact plus both groups. A device rename PUT of the served (Ada-less) card keeps Ada's membership, while a device removal of the visible Grace still applies. Unarchive restores Ada in both served groups and sync. The archived contact page shows 2 checked remembered groups. Trashed members are omitted too.
<!-- SECTION:NOTES:END -->
