---
id: RLDX-2
title: Sign in to the web UI with a passkey via a one-time setup link
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:45'
labels:
  - auth
  - web
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-1
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The web UI holds every contact, so it needs a login. Decision: passkeys (WebAuthn) for the web UI, with no password login. The CardDAV endpoint uses separate app passwords (see the app passwords task) because Apple Contacts supports only HTTP Basic/Digest auth. There is no sign-up page: a rake task prints a single-use, expiring URL that registers a passkey. The same rake task handles first setup and recovery after losing a device, so recovery requires shell access to the server (fly ssh console in production). One user today; keep the User model ready for a second user later. Check whether the current Rails release ships passkey support before adding a gem such as webauthn-ruby.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A rake task creates the user if missing and prints a setup URL that expires after a fixed window (for example 15 minutes)
- [ ] #2 Visiting the setup URL registers a passkey; reusing or visiting an expired URL shows an error and registers nothing
- [ ] #3 Signing in with a registered passkey starts a session; signing out ends it
- [ ] #4 Every web page except sign-in and setup redirects anonymous visitors to sign-in
- [ ] #5 A signed-in user can register additional passkeys and remove any passkey except the last one
- [ ] #6 Tests cover setup-link expiry, single use, and the anonymous redirect
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->
