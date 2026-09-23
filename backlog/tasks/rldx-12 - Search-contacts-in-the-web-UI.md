---
id: RLDX-12
title: Search contacts in the web UI
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
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Scrolling a long contact list does not scale. Search uses the extracted columns kept alongside each raw vCard.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A search box filters contacts by name, organization, email, or phone as the user types
- [ ] #2 Matching ignores case and phone formatting (spaces, dashes, parentheses)
- [ ] #3 Search covers active contacts by default, with a way to include archived ones
- [ ] #4 Trashed contacts never appear in search results
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
