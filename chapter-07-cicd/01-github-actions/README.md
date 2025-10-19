# GitHub Actions CI/CD Pipeline

Complete GitHub Actions workflow for Docker applications.

## Features

✅ **Automated builds** on push and PR
✅ **Multi-platform** images (amd64, arm64)
✅ **Security scanning** with Trivy
✅ **Layer caching** for faster builds
✅ **Multi-environment** deployment (staging, production)
✅ **Semantic versioning** tags
✅ **Automatic cleanup** of old images

## Workflow File

Copy `.github/workflows/deploy.yml` to your repository.

## Pipeline Stages

### 1. Build

```yaml
- Build Docker image
- Push to GitHub Container Registry (ghcr.io)
- Tag with branch name, SHA, and 'latest'
- Use BuildKit cache for speed
- Build for multiple platforms
```

### 2. Security Scan

```yaml
- Scan image with Trivy
- Check for CRITICAL and HIGH vulnerabilities
- Upload results to GitHub Security tab
- Fail build if issues found
```

### 3. Deploy to Staging

```yaml
- Triggers on 'develop' branch
- Deploys to staging environment
- Runs smoke tests
- Environment protection rules
```

### 4. Deploy to Production

```yaml
- Triggers on 'main' branch
- Requires manual approval (environment protection)
- Deploys to production
- Verifies deployment
- Sends notifications
```

### 5. Cleanup

```yaml
- Removes old package versions
- Keeps last 10 versions
- Cleans up pre-release tags
```

## Setup Instructions

### 1. Enable GitHub Container Registry

```bash
# Generate personal access token with packages:write permission
# Settings → Developer settings → Personal access tokens
```

### 2. Add Workflow File

```bash
mkdir -p .github/workflows
cp deploy.yml .github/workflows/
```

### 3. Configure Environments

In your repository:
- Settings → Environments
- Create "staging" and "production"
- Add protection rules for production

### 4. Push to GitHub

```bash
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Actions workflow"
git push
```

### 5. Monitor Workflow

- Go to Actions tab
- Watch your pipeline run!

## Image Tags Generated

| Event | Tags Created |
|-------|-------------|
| Push to `main` | `latest`, `main`, `main-abc1234`, `1.2.3` (if tagged) |
| Push to `develop` | `develop`, `develop-abc1234` |
| Pull Request | `pr-123` |

## Registry Authentication

The workflow uses `GITHUB_TOKEN` automatically:

```yaml
- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

No manual secrets needed!

## Build Cache

BuildKit cache speeds up builds dramatically:

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

### First build: 5 minutes
### Subsequent builds: 30 seconds

## Security Scanning

Trivy scans for:
- OS vulnerabilities
- Application dependencies
- Misconfigurations
- Secrets in images

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail build if issues found
```

## Multi-Platform Builds

Build for multiple architectures:

```yaml
platforms: linux/amd64,linux/arm64
```

Supports:
- Intel/AMD servers
- Apple Silicon (M1/M2)
- ARM servers (Graviton)

## Environment Protection

### Staging
- Auto-deploys on `develop` branch
- No approval required
- Runs smoke tests

### Production
- Auto-deploys on `main` branch
- **Requires approval** from designated reviewers
- Environment-specific secrets
- Deployment logs retained

## Deployment Strategies

### Blue-Green Deployment

```yaml
- name: Deploy with zero downtime
  run: |
    # Start new version
    docker-compose -f docker-compose.blue.yml up -d
    
    # Wait for health checks
    ./wait-for-healthy.sh
    
    # Switch traffic
    ./switch-traffic.sh blue
    
    # Stop old version
    docker-compose -f docker-compose.green.yml down
```

### Rolling Update

```yaml
- name: Rolling update (Kubernetes)
  run: |
    kubectl set image deployment/myapp \
      myapp=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    kubectl rollout status deployment/myapp
```

### Canary Deployment

```yaml
- name: Canary deployment
  run: |
    # Deploy to 10% of servers
    ./deploy-canary.sh 10
    
    # Monitor metrics
    sleep 300
    
    # If healthy, deploy to 100%
    ./deploy-canary.sh 100
```

## Notifications

### Slack Notification

```yaml
- name: Slack notification
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment to ${{ github.ref }} ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Email Notification

```yaml
- name: Send email
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Build failed for ${{ github.repository }}
    body: Build ${{ github.run_number }} failed
    to: team@example.com
```

## Rollback Strategy

### Automatic Rollback

```yaml
- name: Deploy and verify
  run: |
    ./deploy.sh
    
    # Check health
    if ! ./health-check.sh; then
      echo "Health check failed, rolling back"
      ./rollback.sh
      exit 1
    fi
```

### Manual Rollback

```yaml
workflow_dispatch:
  inputs:
    version:
      description: 'Version to rollback to'
      required: true
      
- name: Rollback to version
  run: |
    docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.event.inputs.version }}
    ./deploy.sh ${{ github.event.inputs.version }}
```

## Cost Optimization

### Cleanup Old Images

```yaml
- name: Delete old packages
  uses: actions/delete-package-versions@v5
  with:
    package-name: ${{ env.IMAGE_NAME }}
    min-versions-to-keep: 10
```

### Build Only on Changes

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'Dockerfile'
      - 'package.json'
```

### Use Self-Hosted Runners

```yaml
jobs:
  build:
    runs-on: self-hosted  # Use your own servers
```

## Monitoring Integration

### DataDog

```yaml
- name: DataDog event
  run: |
    curl -X POST "https://api.datadoghq.com/api/v1/events" \
      -H "DD-API-KEY: ${{ secrets.DD_API_KEY }}" \
      -d '{
        "title": "Deployment",
        "text": "Deployed version ${{ github.sha }}",
        "tags": ["environment:production"]
      }'
```

### New Relic

```yaml
- name: New Relic deployment marker
  uses: newrelic/deployment-marker-action@v2
  with:
    apiKey: ${{ secrets.NEW_RELIC_API_KEY }}
    applicationId: ${{ secrets.NEW_RELIC_APP_ID }}
    revision: ${{ github.sha }}
```

## Troubleshooting

### Build fails with "authentication required"?

```yaml
# Ensure GITHUB_TOKEN has packages:write permission
# Repository Settings → Actions → General → Workflow permissions
# Select "Read and write permissions"
```

### Cache not working?

```yaml
# Check cache permissions
# Ensure workflow has cache:write permission
```

### Security scan fails?

```yaml
# Temporarily allow to pass while fixing vulnerabilities
exit-code: '0'  # Don't fail build

# View vulnerabilities
gh api /repos/$OWNER/$REPO/code-scanning/alerts
```

### Deployment times out?

```yaml
# Increase timeout
timeout-minutes: 30

# Or split into smaller jobs
```

## Complete Example Repository

See `example-app/` directory for:
- Full application code
- Dockerfile
- GitHub Actions workflow
- Deployment scripts
- Monitoring setup

## Key Takeaways

✅ Fully automated pipeline from code to production
✅ Security scanning catches vulnerabilities early
✅ Multi-environment support with protection rules
✅ Fast builds with intelligent caching
✅ Multi-platform support for any architecture
✅ Easy rollbacks and monitoring integration

**Reference:** Docker Field Manual, Chapter 7, Pages 195-215
