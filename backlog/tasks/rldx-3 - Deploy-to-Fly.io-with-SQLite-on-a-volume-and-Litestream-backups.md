---
id: RLDX-3
title: Deploy to Fly.io with SQLite on a volume and Litestream backups
status: To Do
assignee: []
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:32'
labels:
  - infra
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-2
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: chore
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple Contacts sends CardDAV credentials with HTTP Basic auth on every request, so the server must run on HTTPS with a publicly trusted certificate before real devices can test sync. Decision: Fly.io, chosen as the cheapest PaaS that stays awake (Render free instances sleep, which breaks background sync). One small machine, SQLite on a persistent volume, and Litestream replicating the database to object storage (for example Fly Tigris). Deploy after passkey sign-in exists so the public URL never serves an unauthenticated app.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 fly deploy ships the app to one machine with SQLite files on a mounted volume
- [ ] #2 The app serves a custom domain over HTTPS with a valid certificate and redirects HTTP to HTTPS
- [ ] #3 Litestream continuously replicates the database, and a documented restore into a fresh volume succeeds
- [ ] #4 The machine stays running when idle (no auto-stop)
- [ ] #5 README documents deploy, running the passkey setup rake task in production, and restore steps
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
