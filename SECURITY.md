# Security policy

## Supported versions

Security fixes are applied to the latest commit on `main`. Tagged demonstration releases are not maintained indefinitely; consumers should update to the latest reviewed release and dependency set.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature for this repository. Do not disclose the issue in a public issue, discussion, pull request, or commit.

Include the affected component, reproduction steps, impact, prerequisites, and any suggested mitigation. Remove credentials, account IDs, customer data, and exploit traffic from the report.

If private vulnerability reporting is unavailable, contact the repository owner through a private channel listed on their GitHub profile and ask for a secure reporting path without sending exploit details in the initial message.

## Response expectations

The maintainer will acknowledge a complete report, assess severity and affected versions, coordinate a fix, and publish remediation guidance when appropriate. Timelines depend on severity, exploitability, and upstream dependencies.

This repository is a reference implementation. Deployers remain responsible for AWS account controls, network boundaries, IAM review, secrets, runtime scanning, incident response, and supported dependency versions.
