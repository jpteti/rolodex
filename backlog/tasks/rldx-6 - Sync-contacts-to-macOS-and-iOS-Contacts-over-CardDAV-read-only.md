---
id: RLDX-6
title: Sync contacts to macOS and iOS Contacts over CardDAV (read-only)
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:09'
labels:
  - carddav
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-3
  - RLDX-4
  - RLDX-5
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
This slice proves Apple client compatibility, the riskiest part of the project. Rolodex serves contacts over CardDAV (RFC 6352 on WebDAV RFC 4918). Apple clients discover the account from /.well-known/carddav, then walk current-user-principal and addressbook-home-set to the address book. Without sync-collection support, they detect changes with the CalendarServer getctag property and per-resource ETags. Apple clients prefer vCard 3.0. Writes, deletes, and sync tokens are later tasks; this one is read-only. Check for a maintained Ruby CardDAV/WebDAV server library before hand-rolling the protocol. Test against a real device on the deployed server.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Adding a CardDAV account on macOS Contacts with only the server hostname, username, and an app password succeeds
- [ ] #2 Adding the account in iOS Settings the same way succeeds
- [ ] #3 All contacts created in the web UI appear on both devices
- [ ] #4 Editing or adding a contact in the web UI appears on the devices after their next refresh, driven by a changed getctag and ETag
- [ ] #5 Requests without valid app-password credentials return 401 with a WWW-Authenticate Basic challenge
- [ ] #6 Request specs cover OPTIONS, PROPFIND on principal/home/address book, addressbook-multiget REPORT, and GET
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Manual sync verified on a physical iPhone and a Mac against the deployed server
- [ ] #2 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Library check: carddav/carddav.rb gems are clients; dav4rack (2013) and dav4rack_ext (2014) are unmaintained. Hand-roll the server.
2. URL tree: /dav/ root -> /dav/principals/<user>/ -> /dav/addressbooks/<user>/ (home) -> /dav/addressbooks/<user>/contacts/ -> <resource>.vcf. /.well-known/carddav 301s to /dav/; PROPFIND and OPTIONS on / serve the root.
3. Dav module: property names, request parsing (prop/allprop/propname), Nokogiri multistatus builder with 200 and 404 propstats.
4. Carddav resources (Root, Principal, Home, AddressBookCollection, ContactResource) define properties: current-user-principal, addressbook-home-set, resourcetype, getctag, getetag, supported-report-set, supported-address-data (vCard 3.0), current-user-privilege-set (read only for now).
5. Carddav::DavController: OPTIONS (DAV: 1, 3, addressbook), PROPFIND with Depth 0/1, PROPPATCH (403 per prop), REPORT addressbook-multiget and addressbook-query, GET/HEAD with ETag and If-None-Match.
6. Allow WebDAV methods in Puma (supported_http_methods).
7. Request tests for each method; manual sync on a Mac and an iPhone against the deployed server.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Found while checking with curl: Puma 8 rejects PROPFIND/REPORT unless listed in supported_http_methods, and integration tests bypass Puma. config/puma.rb now lists the WebDAV methods, and test/config/puma_config_test.rb loads that file to assert it.
Production image check (Docker): OPTIONS 200, PROPFIND 207, REPORT 207, and PROPFIND /.well-known/carddav 301 to /dav/, all through Thruster.
bin/ci: 65 tests + 2 system tests. Device testing waits on the Fly deploy (RLDX-3).
<!-- SECTION:NOTES:END -->
