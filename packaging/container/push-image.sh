#!/usr/bin/env bash
set -euo pipefail

engine="${CONTAINER_ENGINE:-podman}"
source_image="${MODULIX_LAUNCHER_SOURCE_IMAGE:-localhost/modulix-launcher:local}"
target_image="${MODULIX_LAUNCHER_TARGET_IMAGE:-quay.io/l-it/modulix-launcher:local}"

usage() {
  cat <<'EOF'
Tag and push a built modulix-launcher image.

Usage:
  packaging/container/push-image.sh [options]

Options:
  --source-image <name:tag>  Source image (default: localhost/modulix-launcher:local)
  --target-image <name:tag>  Target image (default: quay.io/l-it/modulix-launcher:local)
  --engine <podman|docker>   Container engine (default: podman)
  -h, --help                 Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-image)
      source_image="${2:?missing value for --source-image}"
      shift 2
      ;;
    --target-image)
      target_image="${2:?missing value for --target-image}"
      shift 2
      ;;
    --engine)
      engine="${2:?missing value for --engine}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v "${engine}" >/dev/null 2>&1; then
  echo "Container engine not found: ${engine}" >&2
  exit 1
fi

"${engine}" tag "${source_image}" "${target_image}"
"${engine}" push "${target_image}"

echo "Pushed image: ${target_image}"

