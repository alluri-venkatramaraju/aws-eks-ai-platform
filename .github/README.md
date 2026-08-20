# GitHub automation

This directory contains the repository automation that GitHub runs for pull requests, merges, releases, and dependency maintenance. None of these workflows deploy Terraform or apply Kubernetes manifests directly.

## Files

| File | Purpose |
| --- | --- |
| `dependabot.yml` | Checks supported dependency sources weekly and opens update pull requests. |
| `pull_request_template.md` | Gives contributors a consistent review and validation checklist. |
| `workflows/validate.yml` | Validates the application, Terraform environments, and rendered Kubernetes manifests. |
| `workflows/security.yml` | Scans the repository for secrets, insecure configuration, and policy violations. |
| `workflows/container.yml` | Tests, publishes, attests, and signs the model-server image. |

## Dependabot

Dependabot is GitHub's dependency-update service. The configuration in `dependabot.yml` checks these ecosystems every week:

- GitHub Actions used by the workflows;
- Python packages declared in `pyproject.toml`;
- the Python base image used by the `Dockerfile`;
- Terraform providers locked separately by the dev, stage, and prod roots.

Related updates are grouped where that makes review easier. OpenTelemetry runtime packages form one group, Python development dependencies form another, and GitHub Actions form a third. Docker and Terraform updates remain separate so their runtime and infrastructure impact can be reviewed independently.

Dependabot opens pull requests; it does not merge or deploy changes. Every update must pass the normal validation and security workflows. Helm chart versions, Kustomize image versions, Kubernetes APIs, and application compatibility still require manual review because this configuration does not manage them.

## Validate workflow

`validate.yml` runs for every pull request and every push to `main`.

It runs three independent jobs:

1. `application` installs the Python development dependencies, checks formatting and lint rules with Ruff, and runs Pytest.
2. `terraform` checks formatting and validates the dev, stage, and prod Terraform roots without connecting to a remote backend or creating AWS resources.
3. `kubernetes` renders every GitOps overlay with Kustomize and validates built-in Kubernetes resources with Kubeconform.

Only the newest validation run for a branch is kept active. Older runs are cancelled through the workflow's concurrency setting.

## Security workflow

`security.yml` runs for pull requests and every Monday at 05:17 UTC.

- Gitleaks searches Git history for committed credentials and secrets.
- Checkov evaluates Terraform, Kubernetes, Dockerfile, and GitHub Actions security policies.
- Trivy reports high and critical configuration findings and produces a SARIF report.
- The SARIF report is uploaded to GitHub code scanning so findings appear in the repository Security tab.

The workflow receives read-only repository access plus permission to upload security results. It does not receive AWS credentials.

## Container workflow

`container.yml` runs after a push to `main` or a tag beginning with `v`.

The workflow:

1. builds the image locally;
2. starts it with a read-only filesystem, no Linux capabilities, and `no-new-privileges`;
3. waits for the `/healthz` endpoint;
4. publishes commit and branch or release tags to GitHub Container Registry;
5. creates build provenance and an SBOM;
6. signs the published image digest with keyless Cosign signing.

Publishing requires `packages: write`. Keyless signing requires `id-token: write` so GitHub can issue a short-lived OIDC identity. No long-lived signing key is stored in repository secrets.

## Required repository settings

After pushing the repository to GitHub:

1. Require the Validate and Security jobs in the `main` branch protection rules.
2. Require pull-request review before merging.
3. Keep workflow permissions restricted and allow the container workflow to publish packages.
4. Enable GitHub code scanning and private vulnerability reporting.
5. Configure production environments and required reviewers before adding deployment workflows.
6. Review Dependabot pull requests instead of enabling unrestricted automatic merging.

GitHub Actions are pinned to immutable commit SHAs. The version comments beside each SHA make their upstream release series visible to reviewers. Dependabot may propose newer SHAs, but those changes must still pass review and CI.

## Local equivalents

Run the closest local checks with:

```bash
make test
make validate ENV=dev
make validate ENV=stage
make validate ENV=prod
make security
make build
```

Local validation does not prove that GitHub package permissions, OIDC signing, branch rules, or code-scanning settings are configured correctly. Confirm those controls after the first GitHub workflow runs.
