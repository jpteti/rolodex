---
id: RLDX-2
title: Sign in to the web UI with a passkey via a one-time setup link
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:39'
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
- [x] #1 A rake task creates the user if missing and prints a setup URL that expires after a fixed window (for example 15 minutes)
- [x] #2 Visiting the setup URL registers a passkey; reusing or visiting an expired URL shows an error and registers nothing
- [x] #3 Signing in with a registered passkey starts a session; signing out ends it
- [x] #4 Every web page except sign-in and setup redirects anonymous visitors to sign-in
- [x] #5 A signed-in user can register additional passkeys and remove any passkey except the last one
- [x] #6 Tests cover setup-link expiry, single use, and the anonymous redirect
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Check Rails 8.1.3 for built-in passkeys (none), then use the webauthn gem (3.4.3).
2. Models: User (username, webauthn_id), Passkey (credential id, public key, sign count, name, last used), SetupLink (SHA-256 token digest, expires_at, used_at), Session (Rails 8 auth-generator pattern with a signed cookie).
3. rake rolodex:setup_link creates the user (ROLODEX_USER, default owner) and prints a URL valid for 15 minutes; redemption is an atomic conditional UPDATE so a link works once.
4. Controllers: sessions (options/create/destroy), setups (show/options/create), passkeys (index/options/create/destroy, last one protected). ApplicationController requires authentication by default.
5. A Stimulus passkey controller runs the WebAuthn ceremony and posts JSON back.
6. Integration tests with WebAuthn::FakeClient; a system test with Chrome's virtual authenticator.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rails 8.1.3.1 breaks with json 3.0 (JSON.parse positional options), so the Gemfile pins json ~> 2.21.
System test caught two real bugs: the CSRF meta tag is absent in the test env, and the fixture webauthn_id was not valid base64url. Both fixed.
bin/ci passes locally (16 tests + 1 system test) and on PR #6, whose base is skeleton/rldx-1-scaffold.
<!-- SECTION:NOTES:END -->
