---
id: RLDX-11
title: Edit all common contact fields in the web UI
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - web
  - stack-editing
milestone: m-1
dependencies:
  - RLDX-4
  - RLDX-9
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first web form covers only name, organization, emails, and phones. Editing on the web should cover the fields people use in Apple Contacts, while leaving untouched every vCard property the form does not show (the raw vCard is the source of truth). Deleting from the web moves the contact to the Trash, matching device deletes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The form edits name parts, nickname, organization, job title, multiple labeled emails, phones, postal addresses, URLs, birthday, and notes
- [ ] #2 Adding and removing repeated fields (emails, phones, addresses) works without a full page reload (Turbo/Stimulus)
- [ ] #3 Saving preserves every vCard property the form does not display
- [ ] #4 Apple custom labels (X-ABLabel) display and round-trip
- [ ] #5 Delete in the web UI moves the contact to the Trash
- [ ] #6 Edits appear on devices after their next refresh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
