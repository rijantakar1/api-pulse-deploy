# CI — Docker Hub builds (reusable)

App repos do **not** define their own Docker build logic. They call this reusable workflow:

[`reusable-docker-build-push.yml`](../.github/workflows/reusable-docker-build-push.yml)

## Triggered by (in each app repo)

| Event | Branches |
|-------|----------|
| Push / merge to | `main` |
| Push to | `feature-**` (e.g. `feature-login-fix`) |

`api-pulse-deploy` itself does **not** build app images.

## Image tags

On **`main`**:

- `rijantakar1/<service>:latest`
- `rijantakar1/<service>:<package.json version>`
- `rijantakar1/<service>:<version>-<shortsha>`
- `rijantakar1/<service>:main-<shortsha>`

On **`feature-*`**:

- `rijantakar1/<service>:feature-<name>`
- `rijantakar1/<service>:feature-<name>-<shortsha>`

## One-time setup

### 1. Push this workflow to `api-pulse-deploy` `main`

Cross-repo `uses: owner/repo/...@main` only works after the reusable file exists on `main`.

### 2. Docker Hub secrets (each app repo, or a GitHub org)

Create a Docker Hub **Access Token**, then add:

| Secret | Value |
|--------|--------|
| `DOCKERHUB_USERNAME` | e.g. `rijantakar1` |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

Repo → **Settings → Secrets and variables → Actions**.

> Local `docker login` on your Mac does **not** apply to GitHub Actions. Actions need these secrets.

### 3. Allow reusable workflows (if repos are private)

In each **app** repo: **Settings → Actions → General → Access**  
Allow access as needed so it can call workflows from `api-pulse-deploy`.

In **api-pulse-deploy**: **Settings → Actions → General → Access**  
→ “Accessible from repositories in the 'USER' account” (or public).

### 4. Caller workflows (already added)

- `api-pulse-web/.github/workflows/build-push.yml`
- `api-pulse-auth-service/.github/workflows/build-push.yml`
- `api-pulse-analytics-service/.github/workflows/build-push.yml`

Change the Docker Hub namespace by editing `image_name:` in those callers if your Hub user is not `rijantakar1`.
