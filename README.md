# modulix-launcher scripts

## Overview

Use `modulix-launcher` to run Modulix automation playbooks from published container images.
It mounts the current directory as the runtime workspace.
It uses an inventory, a Vault password file, an SSH agent, and host Podman login state.

## Preparation

`modulix-launcher` uses published images on `quay.io`.
Execution mode is nested-only: toolbox starts the run EE with Podman in the toolbox container.
`modulix-launcher` always preloads `RUN_EE_IMAGE` from host into toolbox (`podman save` -> `podman load`)
and forces nested pull policy to `never`.

For a complete local image build/start workflow, see:
`lcp-docs/30-modulix/50-development/02-containers/20-local-modulix-runtime.md`.

```bash
export WORKSPACE_ROOT="$PWD"
export INVENTORY_DIR="$WORKSPACE_ROOT/ansible-inventory/inventories"
export INVENTORY_NAME="<inventory-name>"   # e.g. corp, ...
export VAULT_PASS_FILE="$WORKSPACE_ROOT/.vault-pass.txt"
# optional: disable TLS cert verification for image pulls
export RUN_SKIP_CERT_CHECK=false
[[ -s "$VAULT_PASS_FILE" ]] || { echo "ERROR: missing or empty Vault password file: $VAULT_PASS_FILE" >&2; false; }
command -v modulix-launcher >/dev/null || { echo "ERROR: modulix-launcher not found in PATH" >&2; false; }
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

```bash
# required for SSH: forward your running ssh-agent
test -n "$SSH_AUTH_SOCK"
test -S "$SSH_AUTH_SOCK"
ssh-add -L
```

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

Run a specific playbook in `services` mode:

```bash
modulix-launcher --inventory-dir "$INVENTORY_DIR" services wunderbox \
  --playbook playbooks/services/12-wunderbox-service-stack.yml \
  -i "inventories/$INVENTORY_NAME/inventory.yml" --limit <HOST>
```

Supported `--playbook` forms:
- absolute path (for example `/opt/modulix/ansible/playbooks/services/12-wunderbox-service-stack.yml`)
- `playbooks/...` (resolved to `/opt/modulix/ansible/playbooks/...`)
- `ansible/playbooks/...` (resolved to `/runner/project/ansible/playbooks/...`)
- `<subpath>.yml` (resolved to `/opt/modulix/ansible/playbooks/<subpath>.yml`)

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

If Podman socket is unavailable locally:

```bash
packaging/container/build-image.sh --engine docker --image modulix-launcher:local
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
