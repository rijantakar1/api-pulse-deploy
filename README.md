# API Pulse — Deploy

Docker Compose, Helm, MySQL bootstrap, and Kubernetes manifests for the **API Pulse** demo.

App repos (org `cd-demo`) build/push to Docker Hub; this repo **pulls** those images.

| Repo | Hub image |
|------|-----------|
| `api-pulse-web` | `rajashekhar2390/api-pulse-web` |
| `api-pulse-auth-service` | `rajashekhar2390/api-pulse-auth-service` |
| `api-pulse-analytics-service` | `rajashekhar2390/api-pulse-analytics-service` |

CI notes: [`docs/CI.md`](docs/CI.md)

## Layout

```
api-pulse-deploy/
├── charts/api-pulse/            # Helm chart (Docker Hub images)
├── db/
├── docker-compose.yml           # pulls Hub images
├── scripts/
│   ├── helm-install.sh          # recommended install/upgrade
│   ├── port-forward.sh
│   └── build-images-minikube.sh # optional local builds only
└── kubernetes/                   # plain YAML (also Hub :latest)
```

## Helm (recommended)

```bash
chmod +x scripts/helm-install.sh scripts/port-forward.sh

# Uses rajashekhar2390/*:latest by default
./scripts/helm-install.sh

# Pin a CI tag
IMAGE_TAG=main-abc1234 ./scripts/helm-install.sh

# Private Hub repos — create imagePullSecret
IMAGE_PULL_SECRET=1 \
  DOCKERHUB_USERNAME=rajashekhar2390 \
  DOCKERHUB_TOKEN='...' \
  ./scripts/helm-install.sh

./scripts/port-forward.sh
```

Open http://localhost:8080

Override tags:

```bash
helm upgrade --install api-pulse ./charts/api-pulse -n api-pulse \
  --set images.web.tag=latest \
  --set images.auth.tag=latest \
  --set images.analytics.tag=latest \
  --set imagePullPolicy=Always
```

## Docker Compose

```bash
cp .env.example .env
docker compose pull
docker compose up -d
```

| Service | URL |
|---------|-----|
| Web | http://localhost:8080 |
| Auth | http://localhost:4001 |
| Analytics | http://localhost:4002 |

Demo: `admin@acme.demo` / `admin@globex.demo` — password `password123`

## Plain Kubernetes manifests

```bash
./kubernetes/apply.sh
./scripts/port-forward.sh
```

Deployments use `rajashekhar2390/*:latest` with `imagePullPolicy: Always`.

## Tenancy model

- Shared deployments in namespace `api-pulse`
- Database-per-tenant + `api_pulse_registry`
- Theme from tenant row after login

## Future

Per-tenant image tags via Argo CD / tenant-manager is out of scope for this phase.
