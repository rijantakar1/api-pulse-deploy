# CI — Docker Hub builds + GitOps bump

App workflows (self-contained):

- Build/push image tag `YYYYMMDD-<sha7>`
- On `main` only: commit Helm values in `cd-demo/api-pulse-deploy` (Argo CD syncs)

See also [`CD.md`](CD.md).

## Triggers

| Event | Branches | GitOps bump |
|-------|----------|-------------|
| Push / merge | `main` | Yes |
| Push | `feature-**` | No (build only) |
| Manual | `workflow_dispatch` | If on `main` |

## Secrets (each app repo or org)

| Secret | Value |
|--------|--------|
| `DOCKERHUB_USERNAME` | `rajashekhar2390` |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `DEPLOY_REPO_TOKEN` | GitHub PAT with write access to `cd-demo/api-pulse-deploy` |

## Runner

Labels: `self-hosted`, `macOS`, `X64`, `beacon`

GitOps commits use concurrency group `api-pulse-deploy-gitops` so parallel service merges rebase safely.
