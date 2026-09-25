#!/usr/bin/env bash
set -euo pipefail

size_kb="${1:?usage: record-app-size-baseline.sh <size-kb> [baseline-json]}"
baseline_json="${2:-ci/baselines/simulator-app-size.json}"

python3 - "$size_kb" "$baseline_json" <<'PY'
import json, sys
from pathlib import Path
size, path = int(sys.argv[1]), Path(sys.argv[2])
path.parent.mkdir(parents=True, exist_ok=True)
data = {}
if path.exists():
    data = json.loads(path.read_text())
data["httpjpg.app_kb"] = size
data["note"] = (
    "Floor measured from a simulator Debug build "
    "(CONTENT_SOURCE=mock, unsigned)."
)
path.write_text(json.dumps(data, indent=2) + "\n")
print(f"wrote {path} → {size} KiB")
PY
