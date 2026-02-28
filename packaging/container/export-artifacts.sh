#!/usr/bin/env bash
set -euo pipefail

engine="${CONTAINER_ENGINE:-podman}"
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
  --engine <podman|docker>  Container engine (default: podman)
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

mkdir -p "${output_dir}/rpm" "${output_dir}/bin"

cid="$("${engine}" create "${image}")"
cleanup() {
  "${engine}" rm -f "${cid}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"${engine}" cp "${cid}:/opt/modulix/rpms/." "${output_dir}/rpm/"
"${engine}" cp "${cid}:/usr/local/bin/modulix-launcher" "${output_dir}/bin/modulix-launcher"
chmod 0755 "${output_dir}/bin/modulix-launcher"

echo "Exported artifacts to: ${output_dir}"

