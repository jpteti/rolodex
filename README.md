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

## Sign in

The web UI uses passkeys and has no password login or sign-up page. To register the first passkey, or to recover after losing every passkey, print a setup link from a shell on the server:

```bash
bin/rails rolodex:setup_link
```

The task creates the user `owner` if it does not exist. Set `ROLODEX_USER=name` to use a different username. The link works once and expires after 15 minutes. After you sign in, add or remove passkeys on the Passkeys page.

Passkeys are bound to the host the app runs on. Set `APP_ORIGIN` (for example `https://rolodex.example.com`) outside development. It defaults to `http://localhost:3000`.

## Run CI locally

```bash
bin/ci
```

`bin/ci` runs RuboCop, bundler-audit, the importmap audit, Brakeman, the unit and integration tests, and the system tests. It exits non-zero when any step fails. GitHub Actions runs the same script on every pull request, including pull requests whose base is another feature branch.

The system tests drive headless Chrome with a virtual passkey authenticator. When Chrome is not installed, Selenium Manager downloads Chrome for Testing into `~/.cache/selenium`, and the tests use it. Set `CHROME_BIN` to point at another Chrome binary.

## Stacked pull requests

All work lands through pull requests, stacked with the `gh stack` extension. Read [Branch and PR workflow](backlog/docs/doc-1%20-%20Branch-and-PR-workflow.md) for the rules.

Set up your clone once:

```bash
gh extension install github/gh-stack
git config rerere.enabled true
```
