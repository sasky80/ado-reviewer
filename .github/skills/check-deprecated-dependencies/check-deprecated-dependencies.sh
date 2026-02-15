#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <ecosystem> <package> [version]" >&2
  echo "Supported ecosystems: npm, pip|pypi, nuget" >&2
  exit 1
fi

ECOSYSTEM_RAW="$1"
PACKAGE="$2"
VERSION="${3:-}"

ECOSYSTEM="${ECOSYSTEM_RAW,,}"
if [[ "$ECOSYSTEM" == "pypi" ]]; then
  ECOSYSTEM="pip"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER="$SCRIPT_DIR/adapters/${ECOSYSTEM}.sh"

if [[ ! -f "$ADAPTER" ]]; then
  echo "Unsupported ecosystem: $ECOSYSTEM_RAW (supported: npm, pip|pypi, nuget)" >&2
  exit 1
fi

bash "$ADAPTER" "$PACKAGE" "$VERSION"
