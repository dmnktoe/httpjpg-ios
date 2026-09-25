#!/usr/bin/env bash
set -euo pipefail

app="${1:?usage: measure-app-size.sh <path-to.app>}"
if [[ ! -d "$app" ]]; then
  echo "missing app bundle: $app" >&2
  exit 1
fi

du -sk "$app" | awk '{print $1}'
