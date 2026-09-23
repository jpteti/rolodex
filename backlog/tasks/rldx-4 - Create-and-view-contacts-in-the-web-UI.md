---
id: RLDX-4
title: Create and view contacts in the web UI
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 04:58'
labels:
  - web
  - stack-skeleton
milestone: m-0
dependencies:
  - RLDX-2
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: high
type: feature
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first user-visible slice: add a contact on the web and see it listed. Decision: store each contact as its raw vCard text (the source of truth) plus extracted columns (display name, given/family name, organization, emails, phones) for listing and search. Apple devices send fields a simple app will not model (social profiles, custom X-ABLabel labels, related names, photos); keeping the raw vCard means sync never drops them. Contacts belong to an address book owned by a user so a second user can be added later. Each contact has a stable UID. This task covers a minimal form; full editing is a later task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A signed-in user can create a contact with name, organization, and one or more emails and phones
- [ ] #2 The contact stores a generated vCard with a UID, and the extracted columns match its contents
- [ ] #3 The contact list shows all contacts sorted by family name, then given name, with organization-only contacts sorted by organization
- [ ] #4 A contact detail page shows the stored fields
- [ ] #5 Tests cover vCard generation and field extraction round trips
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Write a Vcard module (parse, unfold/fold at 75 octets, escaping, groups, ordered params) that keeps every property so raw cards round-trip.
2. AddressBook (one per user, ctag counter) and Contact (raw vcard, uid, resource_name, etag, extracted display/given/family/org/emails/phones, sort_key).
3. Extract columns from the vCard on every vCard change; sort_key = family + given, else organization.
4. ContactForm builds a vCard 3.0 (UID, N, FN, ORG, EMAIL, TEL, X-ABSHOWAS for company-only) for new contacts.
5. Contacts index/show/new/create scoped to Current.user's address book; root goes to the list.
6. Model tests for vCard parsing, generation, and extraction round trips; integration and system tests for the web flow.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Wrote an in-house vCard parser instead of a gem: the CardDAV tasks need every property kept in order with raw values, which vcard/vpim do not guarantee.
Verified with bin/ci: 34 tests + 2 system tests (Chrome virtual authenticator signs in, then the contact form creates Katherine Johnson with two emails and one phone).
<!-- SECTION:NOTES:END -->
