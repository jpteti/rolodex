---
id: RLDX-14
title: Show and edit contact photos
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:26'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. ContactPhoto reads PHOTO in vCard 3.0 inline form (ENCODING=b;TYPE=JPEG) and vCard 4.0 data: URIs, and writes uploads as PHOTO;ENCODING=b;TYPE=JPEG.
2. Uploads go through image_processing/libvips: auto-rotate, fit within 512x512, JPEG quality 85, metadata stripped; files over 15 MB or unreadable images are rejected with a message.
3. contacts.has_photo is extracted from the vCard so lists avoid parsing every card.
4. PhotosController show (ETag-cached), update (upload/replace), destroy (remove). The edit page holds the photo form; list and detail pages show the photo or an initials placeholder.
5. Tests: integration tests with generated images, device PUT with a photo, and a system upload test.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Installed libvips locally with Homebrew (CI and the Docker image already install it). Contact#reload now clears the cached parsed card; a stale cache hid new photos in tests.
Verified with bin/ci (123 tests + 6 system tests): initials shown when no photo; a 1600x1200 upload becomes a 512x384 JPEG embedded in the vCard; replace keeps one PHOTO; remove deletes it; a text file is rejected with the vCard unchanged; a device PUT with a JPEG shows on the web; a web photo is returned in the CardDAV GET.
<!-- SECTION:NOTES:END -->
