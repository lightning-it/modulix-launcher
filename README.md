# modulix-launcher scripts

<!-- BEGIN LIT_SHARED_RELEASE_MODEL -->

## Release and Quality Model

This repository follows the Lightning IT shared release and quality model.

See [RELEASE.md](./RELEASE.md) for:

- branch and release flow
- required quality checks
- test matrix
- release evidence
- artifact publishing
- supported repository-specific release behavior

Repository classification: **Container Image**.
Required test profiles: `pre-commit, container-build, container-smoke, trivy, fuzzing, rpm-srpm`.
Publishing targets: `github-release, quay.io`.

## Supported and Tested Platforms

| Platform / Product | Status | Validation |
|---|---:|---|
| ubuntu-latest | Supported | Container CI / Trivy |
| ubi9 | Tested where applicable | Container CI / Trivy |
| podman | Tested where applicable | Container CI / Trivy |
| rpm | Tested where applicable | Container CI / Trivy |

<!-- END LIT_SHARED_RELEASE_MODEL -->

<!-- BEGIN LIT_QUALITY_BADGES -->

[![CI](https://github.com/lightning-it/modulix-launcher/actions/workflows/repository-quality.yml/badge.svg?branch=develop)](https://github.com/lightning-it/modulix-launcher/actions/workflows/repository-quality.yml)
[![Latest Release](https://img.shields.io/github/v/release/lightning-it/modulix-launcher?sort=semver)](https://github.com/lightning-it/modulix-launcher/releases/latest)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/lightning-it/modulix-launcher/badge)](https://scorecard.dev/viewer/?uri=github.com/lightning-it/modulix-launcher)
[![Quay.io](https://img.shields.io/badge/Quay.io-image-blue?logo=quay&logoColor=white)](https://quay.io/repository/l-it/modulix-launcher)
[![Trivy](https://github.com/lightning-it/modulix-launcher/actions/workflows/container-trivy.yml/badge.svg?branch=develop)](https://github.com/lightning-it/modulix-launcher/actions/workflows/container-trivy.yml)
[![Container Build](https://github.com/lightning-it/modulix-launcher/actions/workflows/container-build.yml/badge.svg?branch=develop)](https://github.com/lightning-it/modulix-launcher/actions/workflows/container-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

<!-- END LIT_QUALITY_BADGES -->

## Overview

Use `modulix-launcher` to run Modulix automation playbooks from published container images.
RHEL control hosts only.
Run it from the workspace root that contains `modulix-automation/ansible` and the inventory repo.
It mounts the current directory as the runtime workspace.
It uses an inventory, a Vault password file, `~/.ssh`, and host Podman login state.

## Preparation

`modulix-launcher` uses published images on `quay.io`.
Execution mode is nested-only: toolbox starts the run EE with Podman in the toolbox container.
`modulix-launcher` always preloads `RUN_EE_IMAGE` from host into toolbox (`podman save` -> `podman load`)
and forces nested pull policy to `never`.

For a complete local image build/start workflow, see:
`lcp-docs/30-modulix/50-development/02-containers/20-local-modulix-runtime.md`.

```bash
export WORKSPACE_ROOT="$PWD"
export INVENTORY_DIR="$WORKSPACE_ROOT/ansible-inventory-lit/inventories"
export INVENTORY_NAME="<inventory-name>"   # e.g. corp, ...
export VAULT_PASS_FILE="$WORKSPACE_ROOT/modulix-automation/ansible/.vault-pass.txt"
# optional: disable TLS cert verification for image pulls
export RUN_SKIP_CERT_CHECK=false
[[ -s "$VAULT_PASS_FILE" ]] || { echo "ERROR: missing or empty Vault password file: $VAULT_PASS_FILE" >&2; false; }
if ! command -v modulix-launcher; then
  echo "ERROR: modulix-launcher not found in PATH" >&2
  false
fi
```

If your mirror uses an untrusted/private CA:

```bash
export RUN_SKIP_CERT_CHECK=true
```

First run in connected environment (pull once to host image store):

```bash
podman login quay.io
podman pull "$RUN_EE_IMAGE"
podman pull "$RUN_TOOLBOX_IMAGE"
```

If an image registry requires authentication, you must log in on the host first (`podman login <registry>`).
`modulix-launcher` does not perform registry login and does not manage auth files.

If `SSH_AUTH_SOCK` is set on the host and points to a valid socket,
`modulix-launcher` forwards that agent into toolbox/EE.
If it is unset or invalid, the runtime falls back to the mounted `~/.ssh` material only.

Optional for Vault-backed workflows:
if `VAULT_TOKEN` is set on the host, `modulix-launcher` forwards it into toolbox/EE.
If it is unset, nothing is forwarded.

`--inventory-dir` and Ansible `-i/--inventory` are intentionally different:
- `--inventory-dir`: inventories root path that is mounted into the container runtime.
- `-i/--inventory`: concrete inventory file used by `ansible-playbook`.

## Execution

Open an interactive toolbox shell with the same runtime options/mounts/env as service runs:

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" toolbox shell
```

Before opening the shell, `modulix-launcher` preloads `RUN_EE_IMAGE` into the toolbox (`podman save` -> `podman load`).

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services wunderbox \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services wunderbox --rebuild \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services aap \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services aap --rebuild \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services workbench \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

Run a specific playbook in `services` mode:

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services wunderbox \
  --playbook playbooks/services/12-wunderbox-service-stack.yml \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

Supported `--playbook` forms:
- absolute path (for example `/opt/modulix/ansible/playbooks/services/12-wunderbox-service-stack.yml`)
- `playbooks/...` (resolved to `/runner/project/modulix-automation/ansible/playbooks/...`)

## Operators: Use Published Artifacts

`quay.io/l-it/modulix-launcher` is an artifact carrier image.
It is not the nested Podman runtime for automation execution.
Nested execution happens in the toolbox image.

Pull and export artifacts:

```bash
packaging/container/export-artifacts.sh \
  --image quay.io/l-it/modulix-launcher:latest \
  --output-dir ./dist-export
```

Export result:

- `./dist-export/rpm/*.rpm`
- `./dist-export/bin/modulix-launcher`

## Maintainers: Build And Publish

Builds use `podman`.

Build SRPM:

```bash
packaging/rpm/build-srpm.sh --version 0.1.0 --release 1
```

Install path from RPM:

- `/usr/bin/modulix-launcher`

Build container image (artifact carrier):

```bash
packaging/container/build-image.sh --image localhost/modulix-launcher:local
```

Push image (example):

```bash
podman login quay.io
packaging/container/push-image.sh \
  --source-image localhost/modulix-launcher:local \
  --target-image quay.io/l-it/modulix-launcher:local
```

CI workflow for container build/push:

- `.github/workflows/container-build-publish.yml`

## Security

See [SECURITY.md](./SECURITY.md) for supported versions and vulnerability reporting.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution and review expectations.

## License

See [LICENSE](./LICENSE).

<!-- BEGIN LIT_RELEASE_QUALITY_MODEL -->

## Release and Quality Model

This repository follows the Lightning IT shared release and quality model.
The README shows the current supported and tested matrix.
Exact per-version validation proof is stored with each GitHub Release as `release-evidence.md` and `release-evidence.json`.
Releases are created from the protected `main` branch after a reviewed `develop -> main` release promotion.
Container releases validate build, smoke behavior, Trivy scanning, and Quay.io publishing where enabled.

See:

- [RELEASE.md](./RELEASE.md)
- [TESTING.md](./TESTING.md)
- [GitHub Releases](../../releases)

Repository classification: **Container Image**.
Required test profiles: `pre-commit, container-build, container-smoke, trivy, rpm-srpm`.
Publishing targets: `github-release, quay.io`.

<!-- END LIT_RELEASE_QUALITY_MODEL -->

<!-- BEGIN LIT_COMPATIBILITY_MATRIX -->

## Compatibility Matrix

| Image Version | Base Image | Runtime | Validation |
|---|---|---|---|
| Latest release | ubi9 | Podman / GitHub Actions | See release evidence |
| Latest release | podman | Podman / GitHub Actions | See release evidence |
| Latest release | rpm | Podman / GitHub Actions | See release evidence |

Validation proof for each released version is stored in the corresponding GitHub Release evidence.

<!-- END LIT_COMPATIBILITY_MATRIX -->

## Release Evidence

Every released version includes immutable release evidence attached to the corresponding GitHub Release.
The evidence records:

- tested matrix combinations
- GitHub Actions run links
- artifact references
- publish status
- security scan status

See [GitHub Releases](../../releases), [RELEASE.md](./RELEASE.md), and [TESTING.md](./TESTING.md) for the release process and validation model.
