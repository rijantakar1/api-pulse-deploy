# CI — Amazon ECR builds + GitOps bump

```text
push to main|feature-* → build → ECR push → commit Helm values → Argo CD sync
```

## Triggers

| Event | Branches | GitOps |
|-------|----------|--------|
| push | `main` | Full tag bump (`images.*`, `versions.*`, `versionsActive`) |
| push | `feature-*` | Append `versionsActive` only (canary Deployments) |
| workflow_dispatch | any | Same rules by branch |

## Secrets (app repos)

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | ECR push |
| `AWS_SECRET_ACCESS_KEY` | ECR push |
| `AWS_REGION` | e.g. `us-west-2` |
| `AWS_ACCOUNT_ID` | 12-digit account |
| `DEPLOY_REPO_TOKEN` | Write to `cd-demo/api-pulse-deploy` |

See [ECR.md](./ECR.md) for registry setup and pull secrets.

## Image tags

- **main:** `YYYYMMDD-<sha7>` (+ `:latest` alias)  
- **feature:** `feature-<branch>-<sha7>`

GitOps concurrency group: `api-pulse-deploy-gitops`.
