# Hando

Privacy-first, offline-first operational tool for physical asset handovers.

Working product name is **Hando** (repo and package ids may still say `asset-os` / `asset_os`).

## Status

Product vision lives in the [Complete Idea Summary](docs/vision/complete-idea-summary.md). Flutter web client is at `apps/web` for local validation and customer feedback on GitHub Pages. Native Android/iOS packaging is deferred until after feedback.

## Project Philosophy

- Local-first: business data remains on-device by default.
- Offline-first: core workflows work without internet access.
- Cloud-optional: sync and backup are additive, not required.
- Privacy-first: collect only what operations need.
- Simplicity-first: optimize for fast, low-friction field usage.

## Documentation

- **Start here:** [Complete Idea Summary](docs/vision/complete-idea-summary.md)
- Index: [Documentation Index](docs/README.md)
- Stack decision: [ADR-001: Flutter Web Client](docs/architecture/decisions/ADR-001-mobile-stack.md)

## App

Flutter web client: [`apps/web`](apps/web).

## Dev commands (WSL, web)

From the repo root inside WSL:

```bash
./scripts/setup.sh
./scripts/localrun.sh      # Chrome if available, else web-server URL
./scripts/test.sh
./scripts/wsldeploy.sh     # flutter build web → apps/web/build/web

# or one entrypoint
./scripts/dev.sh setup|localrun|test|wsldeploy|servelocal|doctor
```

From Windows PowerShell:

```powershell
.\scripts\wsl.ps1 setup
.\scripts\wsl.ps1 localrun
.\scripts\wsl.ps1 test
.\scripts\wsl.ps1 wsldeploy
.\scripts\wsl.ps1 servelocal
```

### Customer feedback (GitHub Pages)

Public preview URL: [https://kamal01236.github.io/asset-os/](https://kamal01236.github.io/asset-os/)

1. Local preview: `./scripts/localrun.sh` — open the printed URL.
2. Public preview: push to `main` (or run **Actions → Deploy GitHub Pages → Run workflow**). CI builds Flutter web with `--base-href /asset-os/` and publishes via [`.github/workflows/pages-deploy.yml`](.github/workflows/pages-deploy.yml).

**One-time GitHub Pages setup:**

1. Repo is currently **private**. GitHub Pages for private repos needs **GitHub Pro** (or make the repo **public**).
2. Open the repo on GitHub → **Settings → Pages → Build and deployment → Source**: select **GitHub Actions**.
3. After the first successful workflow run, open the Pages URL above.
4. Optionally remove obsolete **Production** environment secrets (`FLY_API_TOKEN`, optional `FLY_APP` / `FLY_ORG`) if they remain from the old Fly.io deploy.
