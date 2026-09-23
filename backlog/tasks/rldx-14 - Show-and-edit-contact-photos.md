---
id: RLDX-14
title: Show and edit contact photos
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - web
  - stack-editing
milestone: m-1
dependencies:
  - RLDX-11
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: low
type: feature
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Photos set on devices already sync because the raw vCard keeps the PHOTO property. The web UI should display them and let the user change them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Contact list and detail pages show the vCard photo, with an initials placeholder when absent
- [ ] #2 The user can upload, replace, and remove a photo in the web UI
- [ ] #3 Uploaded photos are resized to a reasonable size before being embedded in the vCard
- [ ] #4 Photos set in the web UI appear on devices, and photos set on devices appear in the web UI
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
