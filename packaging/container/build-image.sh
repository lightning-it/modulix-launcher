#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

engine="${CONTAINER_ENGINE:-podman}"
image="${MODULIX_LAUNCHER_IMAGE:-localhost/modulix-launcher:local}"
containerfile="${MODULIX_LAUNCHER_CONTAINERFILE:-${REPO_ROOT}/Containerfile}"

usage() {
  cat <<'EOF'
Build the modulix-launcher container image.

Usage:
  packaging/container/build-image.sh [options]

Options:
  --image <name:tag>        Image name (default: localhost/modulix-launcher:local)
  --engine <podman|docker>  Container engine (default: podman)
  --containerfile <path>    Containerfile path (default: ./Containerfile)
  -h, --help                Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      image="${2:?missing value for --image}"
      shift 2
      ;;
    --engine)
      engine="${2:?missing value for --engine}"
      shift 2
      ;;
    --containerfile)
      containerfile="${2:?missing value for --containerfile}"
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

if [[ "${containerfile}" != /* ]]; then
  containerfile="${REPO_ROOT}/${containerfile}"
fi

if [[ ! -f "${containerfile}" ]]; then
  echo "Containerfile not found: ${containerfile}" >&2
  exit 1
fi

"${engine}" build \
  --file "${containerfile}" \
  --tag "${image}" \
  "${REPO_ROOT}"

echo "Built image: ${image}"

