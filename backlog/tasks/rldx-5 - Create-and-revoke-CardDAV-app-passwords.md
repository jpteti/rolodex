---
id: RLDX-5
title: Create and revoke CardDAV app passwords
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:40'
labels:
  - auth
  - web
  - carddav
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-2
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple Contacts authenticates CardDAV accounts with a username and password over HTTP Basic auth and cannot use passkeys. Decision: per-device app passwords, created in the web UI, each revocable, stored hashed. The same pattern iCloud and Fastmail use. The CardDAV endpoint accepts only app passwords; the web UI accepts only passkeys.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A signed-in user can create a named app password (for example iPhone) and sees the generated secret exactly once
- [x] #2 The app password list shows name, creation time, and last-used time, never the secret
- [x] #3 Revoking an app password makes the next CardDAV request with it return 401
- [x] #4 Secrets are stored hashed, and Basic auth compares them in constant time
- [x] #5 Basic auth requests over plain HTTP are refused in production
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. AppPassword model: name, SHA-256 secret_digest, last_used_at. Secrets are 20 random chars (100 bits) from an unambiguous alphabet, shown in 5-char groups.
2. AppPassword.authenticate finds the user and compares each digest with ActiveSupport::SecurityUtils.secure_compare.
3. CarddavAuthentication concern: refuse plain HTTP when config.x.carddav_require_https (403), then Basic auth with realm 'Rolodex CardDAV'; touch last_used_at at most once a minute.
4. Carddav::BaseController (no sessions/CSRF) with a placeholder /dav/ endpoint that RLDX-6 replaces.
5. Web UI: list (name, created, last used), create (secret shown once with setup instructions), revoke.
6. Production: assume_ssl false so X-Forwarded-Proto from Fly decides request.ssl?; carddav_require_https true.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
config.x returns an empty (truthy) OrderedOptions for unset keys, so application.rb sets carddav_require_https = false explicitly.
Verified with bin/ci (45 tests): secret shown once and absent from the list and the database, revoke then 401 with WWW-Authenticate Basic, secure_compare called on digests, plain HTTP 403 when HTTPS is required and 200 over HTTPS.
<!-- SECTION:NOTES:END -->
