---
id: RLDX-17
title: Manage groups in the web UI
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
labels:
  - web
  - stack-groups
milestone: m-1
dependencies:
  - RLDX-16
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: low
type: feature
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After groups sync from devices, the user should also be able to organize them on the web.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The user can create, rename, and delete groups
- [x] #2 The user can add contacts to and remove contacts from groups on the contact page
- [ ] #3 Group changes made in the web UI appear on devices after their next refresh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Group.create_named writes an Apple group vCard (N, FN, X-ADDRESSBOOKSERVER-KIND:group, UID); blank names are rejected.
2. Group#rename rewrites N and FN only; #add_member and #remove_member add or drop X-ADDRESSBOOKSERVER-MEMBER lines and leave other properties alone. Each save updates memberships, logs a sync change, and bumps getctag, so devices pick it up.
3. Web: /groups gets create, rename (edit page), and delete (confirm; contacts stay); the contact page has group checkboxes saved by ContactGroupsController.
4. Integration tests that check the web change and the sync-collection result.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (151 tests): a created group shows up in sync-collection and GET as an Apple group vCard; rename keeps members and a custom property; delete leaves contacts and reports a 404 in sync; checkboxes add Ada to Family and remove her from Work, and both groups appear in sync; saving unchanged checkboxes leaves the vCards untouched and reports no changes. AC 3 on devices waits on the deploy.
<!-- SECTION:NOTES:END -->
