# Rolodex

Rolodex is a simple contact manager with archiving functionality. It serves a web UI and a CardDAV endpoint that macOS and iOS Contacts sync with.

The app runs on Rails 8 with Hotwire (Turbo and Stimulus) and uses SQLite in every environment.

## Setup

Install Ruby 4.0.6 (see `.ruby-version`) and SQLite 3, then run:

```bash
bin/setup --skip-server
```

`bin/setup` installs gems and prepares the development database.

## Run the app

```bash
bin/dev
```

The app listens on http://localhost:3000.

## Run CI locally

```bash
bin/ci
```

`bin/ci` runs RuboCop, bundler-audit, the importmap audit, Brakeman, and the test suite. It exits non-zero when any step fails. GitHub Actions runs the same script on every pull request, including pull requests whose base is another feature branch.

## Stacked pull requests

All work lands through pull requests, stacked with the `gh stack` extension. Read [Branch and PR workflow](backlog/docs/doc-1%20-%20Branch-and-PR-workflow.md) for the rules.

Set up your clone once:

```bash
gh extension install github/gh-stack
git config rerere.enabled true
```
