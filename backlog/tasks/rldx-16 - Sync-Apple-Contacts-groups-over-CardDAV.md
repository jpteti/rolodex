---
id: RLDX-16
title: Sync Apple Contacts groups over CardDAV
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:34'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. groups table (uid, resource_name, raw vcard, name) and group_memberships keyed by contact UID, as group vCards list members.
2. Vcard::Card#group? (X-ADDRESSBOOKSERVER-KIND or KIND = group) and #member_uids.
3. AddressBook#store_from_device parses a PUT and routes group cards to Group and others to Contact; a resource cannot switch kind. Groups log sync changes and bump getctag like contacts.
4. CardDAV serves groups next to contacts through a generic CardResource (PROPFIND, multiget, GET, sync-collection); DELETE of a group removes it.
5. .vcf import routes group cards to groups.
6. Web: /groups lists groups with member counts; the contact list filters by group; contact pages list their groups.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (145 tests): a group PUT creates a Group and no Contact; GET and multiget return the stored group vCard; an If-Match update changes getctag and appears in sync-collection for the other device; DELETE removes the group and reports 404 in sync; a contact cannot become a group (400); group cards never appear in the contact list; the web lists and filters by group.
AC 2 on real devices waits on the deploy.
<!-- SECTION:NOTES:END -->
