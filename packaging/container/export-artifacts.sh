#!/usr/bin/env bash
set -euo pipefail

image="${MODULIX_LAUNCHER_IMAGE:-localhost/modulix-launcher:local}"
output_dir="${MODULIX_LAUNCHER_EXPORT_DIR:-./dist-export}"

usage() {
  cat <<'EOF'
Export modulix-launcher artifacts from a built or pulled container image.

Exports:
  - RPM(s) from /opt/modulix/rpms
  - launcher script from /usr/local/bin/modulix-launcher

Usage:
  packaging/container/export-artifacts.sh [options]

Options:
  --image <name:tag>        Image name (default: localhost/modulix-launcher:local)
  --output-dir <path>       Output directory (default: ./dist-export)
  -h, --help                Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      image="${2:?missing value for --image}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:?missing value for --output-dir}"
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

if ! command -v podman >/dev/null 2>&1; then
  echo "Container engine not found: podman" >&2
  exit 1
fi

mkdir -p "${output_dir}/rpm" "${output_dir}/bin"

cid="$(podman create "${image}")"
cleanup() {
  podman rm -f "${cid}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

podman cp "${cid}:/opt/modulix/rpms/." "${output_dir}/rpm/"
podman cp "${cid}:/usr/local/bin/modulix-launcher" "${output_dir}/bin/modulix-launcher"
chmod 0755 "${output_dir}/bin/modulix-launcher"

echo "Exported artifacts to: ${output_dir}"
