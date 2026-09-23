---
id: RLDX-12
title: Search contacts in the web UI
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-23 04:30'
updated_date: '2026-09-23 05:28'
labels:
  - web
  - stack-web
milestone: m-1
dependencies:
  - RLDX-4
documentation:
  - backlog/docs/doc-1 - Branch-and-PR-workflow.md
priority: medium
type: feature
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Scrolling a long contact list does not scale. Search uses the extracted columns kept alongside each raw vCard.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A search box filters contacts by name, organization, email, or phone as the user types
- [ ] #2 Matching ignores case and phone formatting (spaces, dashes, parentheses)
- [ ] #3 Search covers active contacts by default, with a way to include archived ones
- [ ] #4 Trashed contacts never appear in search results
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All PRs for this task merged to main through the stack workflow in doc-1, with bin/ci passing in GitHub Actions
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extract search_text (display, given, family, nickname, organization, emails; lowercased) and phone_digits (digits only) on every vCard write; a migration backfills existing rows.
2. Contact.search: LIKE on search_text with wildcards escaped, OR on phone_digits when the query has 3+ digits.
3. Index scope: active by default; untrashed with the Include archived checkbox. Trashed contacts are never searched.
4. UI: a search form that targets a Turbo frame; a Stimulus controller submits it 200 ms after each keystroke; the frame targets _top so result links open full pages; archived results carry a badge.
5. Integration and system tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with bin/ci (130 tests + 7 system tests): case-insensitive name/org/email matches; phone matches for 5550102030, 010-2030, and (555) 999 against stored +1 (555) 010-2030 and 555.999.1234; % and _ literal; archived only with the checkbox; trashed never (also closes the search half of RLDX-9 AC 4); the system test typed 'hop' and saw only Grace Hopper, then a phone query, then opened the result.
<!-- SECTION:NOTES:END -->
