# modulix-launcher container packaging

This directory contains helper scripts for building and exporting artifacts from
the `modulix-launcher` container image.
The image is an artifact carrier (RPM + launcher binary), not the nested
automation runtime.

## Build image

```bash
packaging/container/build-image.sh --image localhost/modulix-launcher:local
```

If Podman socket is unavailable on your host:

```bash
packaging/container/build-image.sh --engine docker --image modulix-launcher:local
```

## Push image

```bash
podman login quay.io
packaging/container/push-image.sh \
  --source-image localhost/modulix-launcher:local \
  --target-image quay.io/l-it/modulix-launcher:local
```

## Export artifacts from pulled image

```bash
packaging/container/export-artifacts.sh \
  --image quay.io/l-it/modulix-launcher:local \
  --output-dir ./dist-export
```

Result:

- `./dist-export/rpm/*.rpm` (binary RPM)
- `./dist-export/bin/modulix-launcher` (standalone launcher script)

## CI build/push

Workflow: `.github/workflows/container-build-publish.yml`

- Pull requests: build only (no push)
- Release publish: build and push
- Manual dispatch: optional push via input flag

Required secrets for push:

- `QUAY_USERNAME`
- `QUAY_PASSWORD`
