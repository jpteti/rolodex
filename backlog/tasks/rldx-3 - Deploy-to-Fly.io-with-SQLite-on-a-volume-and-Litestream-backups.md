---
id: RLDX-3
title: Deploy to Fly.io with SQLite on a volume and Litestream backups
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:39'
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
- [x] #5 README documents deploy, running the passkey setup rake task in production, and restore steps
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Dockerfile: install Litestream 0.5.17, add libssl-dev for the openssl gem, serve Thruster on 8080, keep a non-root rails user.
2. Entrypoint: start as root to chown the Fly volume, restore production.sqlite3 from the bucket if missing (litestream restore -if-db-not-exists -if-replica-exists), db:prepare, then exec litestream replicate -exec the server as uid 1000.
3. config/litestream.yml replicates the primary DB to Tigris using the secrets fly storage create sets.
4. fly.toml: volume at /rails/storage, force_https, auto_stop_machines off, min_machines_running 1, /up check, Solid Queue in Puma.
5. README: first deploy, custom domain cert, production setup link, restore steps.
6. Verify locally with Docker + MinIO, then deploy to Fly with the user's account and domain.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Local verification (OrbStack Docker + MinIO standing in for Tigris): the image builds; the entrypoint prepared the DB and ran Puma + Solid Queue under litestream replicate; after creating a contact, deleting the container and its volume, and starting on a new empty volume, the contact came back from the replica. In the container, rolodex:setup_link printed an https URL; /dav/ over X-Forwarded-Proto http got 301 to https; over https it got 401.
Remaining: the real Fly deploy, custom domain, and HTTPS certificate need the user's Fly account and DNS.
<!-- SECTION:NOTES:END -->
