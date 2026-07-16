# Continuous Delivery (Argo CD)

GitOps CD for API Pulse on Minikube.

```text
merge to main → CI build/push YYYYMMDD-<sha7> → commit Helm values → Argo CD sync → Minikube
```

## Image tags

Format: `YYYYMMDD-<gitsha7>` (UTC date + short commit).

Example: `<account>.dkr.ecr.us-west-2.amazonaws.com/api-pulse-web:20260712-a1b2c3d`

See [ECR.md](./ECR.md) for registry + pull-secret setup.

## Secrets

### App repos (or org `cd-demo`)

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | IAM user for ECR push |
| `AWS_SECRET_ACCESS_KEY` | IAM secret |
| `AWS_REGION` | e.g. `us-west-2` |
| `AWS_ACCOUNT_ID` | 12-digit account |
| `DEPLOY_REPO_TOKEN` | GitHub PAT with **contents: write** on `cd-demo/api-pulse-deploy` |

Create a PAT: GitHub → Settings → Developer settings → Personal access tokens  
Scopes: `repo` (or fine-grained: read/write contents on `api-pulse-deploy` only).

### Argo CD (cluster)

| Env / secret | Purpose |
|--------------|---------|
| `ARGOCD_REPO_TOKEN` | PAT that can **read** `cd-demo/api-pulse-deploy` |
| `ARGOCD_REPO_USERNAME` | Your GitHub username (e.g. `rijantakar1`) |
| Optional `ECR_PULL_SECRET=1` + AWS env | Creates/refreshes `ecr-pull` in namespaces |

#### Fix: `authorization failed: Write access to repository not granted`

Argo only needs **read**, but GitHub often returns that message when the token cannot access the repo.

1. Create a **fine-grained PAT** (or classic `repo` PAT):
   - Resource owner: **`cd-demo`** (the org), not only your user
   - Repository access: **Only select repositories** → `api-pulse-deploy`
   - Permissions → **Contents: Read-only** (and Metadata: Read)
2. Re-register the credential:

```bash
export ARGOCD_REPO_TOKEN='github_pat_...'   # or ghp_...
export ARGOCD_REPO_USERNAME='rijantakar1'   # your GitHub login, not "git"
cd ~/Desktop/Projects/argocd-demo/api-pulse-deploy
./scripts/bootstrap-argocd-app.sh
kubectl -n argocd get application api-pulse
```

3. Confirm the token works outside Argo:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $ARGOCD_REPO_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/cd-demo/api-pulse-deploy
# expect 200
```

If that returns `404`/`401`, the token still cannot see the repo (wrong owner, missing repo selection, or org policy).

## Bootstrap Minikube + Argo CD (once)

```bash
minikube start
cd /path/to/api-pulse-deploy

chmod +x scripts/install-argocd.sh scripts/bootstrap-argocd-app.sh
./scripts/install-argocd.sh

# Private deploy repo access for Argo:
export ARGOCD_REPO_TOKEN='ghp_...'
./scripts/bootstrap-argocd-app.sh

# UI
kubectl -n argocd port-forward svc/argocd-server 8081:443
# https://localhost:8081  user: admin  (password printed by install script)
```

Watch the app:

```bash
kubectl -n argocd get application api-pulse
kubectl -n api-pulse get pods -w
```

## Day-2: deploy by merging code

1. Merge a PR to `main` on `api-pulse-web` / `auth-service` / `analytics-service`
2. Actions: build → push Hub tag → commit `images.<svc>.tag` in this repo
3. Argo CD auto-syncs (selfHeal on) → Deployment rolls out

Manual values bump (for testing Argo without CI):

```bash
./scripts/bump_values.py charts/api-pulse/values.yaml analytics 20260712-testdemo
git add charts/api-pulse/values.yaml
git commit -m "chore(cd): bump analytics image to 20260712-testdemo"
git push origin main
```

## E2E checklist

1. [ ] Argo CD installed; Application `api-pulse` Healthy/Synced  
2. [ ] `DEPLOY_REPO_TOKEN` set on app repos  
3. [ ] Merge (or push) to analytics `main`  
4. [ ] Actions: image pushed to ECR `…/api-pulse-*:YYYYMMDD-sha`  
5. [ ] Deploy repo gets commit `chore(cd): bump analytics image to ...`  
6. [ ] Argo Application syncs; pod image shows new tag  
7. [ ] UI Environment Info / `/health` shows matching version string  

## Feasibility notes (Mac + VPN + Minikube)

- Argo CD runs **inside** Minikube; it does not need the Actions runner to kubectl-deploy.
- Runner only builds, pushes Hub, and commits GitOps.
- VPN must allow Minikube pods to pull from ECR and Argo to reach GitHub.
- Keep Minikube running while testing CD.

## Layout

```text
argocd/
  namespace.yaml
  project.yaml
  application.yaml
scripts/
  install-argocd.sh
  bootstrap-argocd-app.sh
  bump_values.py
charts/api-pulse/
  values.yaml          # source of truth for image tags
```
