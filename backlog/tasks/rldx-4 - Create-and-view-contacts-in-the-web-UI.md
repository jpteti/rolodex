---
id: RLDX-4
title: Create and view contacts in the web UI
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - web
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-2
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first user-visible slice: add a contact on the web and see it listed. Decision: store each contact as its raw vCard text (the source of truth) plus extracted columns (display name, given/family name, organization, emails, phones) for listing and search. Apple devices send fields a simple app will not model (social profiles, custom X-ABLabel labels, related names, photos); keeping the raw vCard means sync never drops them. Contacts belong to an address book owned by a user so a second user can be added later. Each contact has a stable UID. This task covers a minimal form; full editing is a later task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A signed-in user can create a contact with name, organization, and one or more emails and phones
- [ ] #2 The contact stores a generated vCard with a UID, and the extracted columns match its contents
- [ ] #3 The contact list shows all contacts sorted by family name, then given name, with organization-only contacts sorted by organization
- [ ] #4 A contact detail page shows the stored fields
- [ ] #5 Tests cover vCard generation and field extraction round trips
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
