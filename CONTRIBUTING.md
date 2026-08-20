# Contributing

Thank you for improving the AWS EKS AI Platform reference implementation.

## Development workflow

1. Create a focused branch from `main`.
2. Read the README for the component being changed and follow the repository's engineering standards.
3. Keep changes small and preserve Terraform, GitOps, and application ownership boundaries.
4. Add meaningful tests and documentation.
5. Run the relevant validation before opening a pull request:

   ```bash
   python3 -m venv .venv
   . .venv/bin/activate
   pip install -e '.[dev]'
   make test
   make validate ENV=dev
   make security
   ```

6. Complete the pull-request checklist and describe security, cost, migration, and rollback implications.

Do not commit credentials, Terraform state, `.tfvars` files, kubeconfig files, customer data, generated secrets, or real production identifiers.

## Commit style

Use concise conventional prefixes such as `feat:`, `fix:`, `test:`, `docs:`, `security:`, and `chore:`. Prefer one logical concern per commit.

## Architecture changes

Changes to cluster ownership, identity, networking, deployment flow, autoscaling, observability backends, or environment isolation require an ADR. Supersede prior decisions rather than rewriting their history.

## Reporting vulnerabilities

Do not open public issues for suspected vulnerabilities. Follow `SECURITY.md`.
