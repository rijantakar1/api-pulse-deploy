# CI — Docker Hub builds (reusable)

App repos do **not** define their own Docker build logic. They call this reusable workflow:

[`reusable-docker-build-push.yml`](../.github/workflows/reusable-docker-build-push.yml)

## Triggered by (in each app repo)

| Event | Branches |
|-------|----------|
| Push / merge to | `main` |
| Push to | `feature-**` (e.g. `feature-login-fix`) |

`api-pulse-deploy` itself does **not** build app images.

Default runner labels: `self-hosted`, `macOS`, `X64`, `beacon`.

## Image tags

Docker Hub namespace: **`rajashekhar2390`**

On **`main`**:

- `rajashekhar2390/<service>:latest`
- `rajashekhar2390/<service>:<package.json version>`
- `rajashekhar2390/<service>:<version>-<shortsha>`
- `rajashekhar2390/<service>:main-<shortsha>`

On **`feature-*`**:

- `rajashekhar2390/<service>:feature-<name>`
- `rajashekhar2390/<service>:feature-<name>-<shortsha>`

## One-time setup

### 1. Push this workflow to `api-pulse-deploy` `main`

Cross-repo `uses: owner/repo/...@main` only works after the reusable file exists on `main`.

### 2. Fix “workflow was not found” (private repos) — required

Your GitHub repos are **private**. Share reusable workflows from deploy:

1. Open: https://github.com/cd-demo/api-pulse-deploy/settings/actions  
2. Scroll to **Access**  
3. Select: **Accessible from repositories in the `cd-demo` organization**  
4. Save  

Also confirm org Actions permissions:  
https://github.com/organizations/cd-demo/settings/actions  

### 3. Docker Hub secrets (each app repo)

| Secret | Value |
|--------|--------|
| `DOCKERHUB_USERNAME` | `rajashekhar2390` |
| `DOCKERHUB_TOKEN` | Docker Hub access token for that account |

Repo → **Settings → Secrets and variables → Actions**.

> Must match the image owner. Pushing to `rajashekhar2390/...` while logged in as a different user will fail.

### 4. Self-hosted runner

Labels: `self-hosted`, `macOS`, `X64`, `beacon`

Docker Desktop must be running on the runner host.

### 5. Caller workflows

- `api-pulse-web` → `rajashekhar2390/api-pulse-web`
- `api-pulse-auth-service` → `rajashekhar2390/api-pulse-auth-service`
- `api-pulse-analytics-service` → `rajashekhar2390/api-pulse-analytics-service`
