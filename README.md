# Hando

Privacy-first, offline-first operational tool for physical asset handovers.

Working product name is **Hando** (repo and package ids may still say `asset-os` / `asset_os`).

## Status

Product vision lives in the [Complete Idea Summary](docs/vision/complete-idea-summary.md). Flutter web client is at `apps/web` for local validation and customer feedback on Fly.io. Native Android/iOS packaging is deferred until after feedback.

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
./scripts/flydeploy.sh     # deploy to Fly.io for customer feedback

# or one entrypoint
./scripts/dev.sh setup|localrun|test|wsldeploy|flydeploy|doctor
```

From Windows PowerShell:

```powershell
.\scripts\wsl.ps1 setup
.\scripts\wsl.ps1 localrun
.\scripts\wsl.ps1 test
.\scripts\wsl.ps1 wsldeploy
.\scripts\wsl.ps1 flydeploy
```

### Customer feedback (Fly.io)

1. One-time: install [flyctl](https://fly.io/docs/hands-on/install-flyctl/), then `fly auth login`.
2. First deploy creates the app if needed (see `fly.toml`); share the public URL after deploy.
3. Local preview: `./scripts/localrun.sh` — open the printed URL.
4. Public preview: `./scripts/flydeploy.sh` (or `.\scripts\wsl.ps1 flydeploy`).

`flydeploy` fails clearly if the Fly CLI is missing or you are not authenticated.

### Deploy / GitHub Production secrets

Pushes to `main` (and manual **workflow_dispatch**) run [`.github/workflows/fly-deploy.yml`](.github/workflows/fly-deploy.yml), which deploys with `flyctl deploy --remote-only` using the GitHub Environment named **Production**. The Docker build (Flutter web → nginx) runs on Fly builders; the runner only needs the Fly CLI.

**One-time Fly app (before or on first CI deploy):** create the app if it does not exist yet (local `./scripts/flydeploy.sh` does this automatically):

```bash
fly apps create asset-os-web
# or: fly apps create asset-os-web --org <your-org-slug>
```

Region/default config comes from `fly.toml` (`primary_region = "sin"`).

**Create the GitHub Environment and credentials:**

1. Open the repo on GitHub → **Settings** → **Environments** → **New environment** → name it exactly `Production`.
2. Under that environment, add:

| Kind | Name | Required | Notes |
|------|------|----------|--------|
| **Secret** | `FLY_API_TOKEN` | Yes | Deploy token from flyctl (see below) |
| **Variable** | `FLY_APP` | No | Override app name; otherwise `fly.toml` (`asset-os-web`) |
| **Variable** | `FLY_ORG` | No | Org slug if your account/org requires it |

3. Generate a deploy token (preferred, app-scoped):

```bash
fly tokens create deploy -a asset-os-web
```

Or an org-scoped deploy token:

```bash
fly tokens create org
```

Copy the token value into the Production environment secret `FLY_API_TOKEN`. Do not commit the token.

4. After the secret is set and the app exists, the **first push to `main`** (including this workflow) triggers **Actions → Fly Deploy** automatically. You can also run it manually via **workflow_dispatch**.
