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

## Deploy

Rolodex runs on one Fly.io machine. SQLite lives on a Fly volume mounted at `/rails/storage`, and Litestream replicates the main database to a Tigris bucket. The machine never auto-stops, so devices can sync at any time.

### First deploy

1. Install flyctl and sign in: `brew install flyctl && fly auth login`.
2. Create the app, then set `app` and `primary_region` in `fly.toml` to match: `fly apps create <app-name>`.
3. Create the volume in the same region: `fly volumes create rolodex_data --size 1 --region <region>`.
4. Create the backup bucket: `fly storage create`. It sets `BUCKET_NAME`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` as app secrets.
5. Set the Rails secret: `fly secrets set SECRET_KEY_BASE=$(bin/rails secret)`.
6. Set `APP_ORIGIN` in `fly.toml` to the custom domain, for example `https://rolodex.example.com`. Passkeys are bound to this host.
7. Deploy: `fly deploy`.
8. Add the domain's certificate, then create the DNS records that `fly certs add` prints: `fly certs add rolodex.example.com`. Check progress with `fly certs show rolodex.example.com`.

Fly redirects HTTP to HTTPS at its edge (`force_https`), and Rails redirects again if a request arrives over plain HTTP. CardDAV refuses Basic auth over plain HTTP.

### Register a passkey in production

```bash
fly ssh console -C "/rails/bin/rails rolodex:setup_link"
```

Open the printed link within 15 minutes. Use the same command to recover after losing every passkey.

### Deploy changes

```bash
fly deploy
```

### Restore the database

On boot, the entrypoint restores `production.sqlite3` from the bucket when the volume has no database. To restore into a fresh volume:

1. Create a volume: `fly volumes create rolodex_data --size 1 --region <region>`.
2. List machines and volumes: `fly machines list` and `fly volumes list`.
3. Destroy the old machine (`fly machine destroy <machine-id> --force`), and destroy or keep the old volume.
4. Run `fly deploy`. The new machine mounts the empty volume and restores the database before Rails starts.

To inspect a backup without replacing the live database, restore it to a separate file:

```bash
fly ssh console -C "litestream restore -config /rails/config/litestream.yml -o /tmp/restored.sqlite3 /rails/storage/production.sqlite3"
```

## Stacked pull requests

All work lands through pull requests, stacked with the `gh stack` extension. Read [Branch and PR workflow](backlog/docs/doc-1%20-%20Branch-and-PR-workflow.md) for the rules.

Set up your clone once:

```bash
gh extension install github/gh-stack
git config rerere.enabled true
```
