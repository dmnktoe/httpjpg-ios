#!/usr/bin/env bash
# Compare a measured kibibyte size against ci/baselines/simulator-app-size.json.
# Soft ceiling: warn (exit 0) under +5%, fail at or above +10%. Missing baseline is informational.
set -euo pipefail

size_kb="${1:?usage: compare-app-size.sh <size-kb> [baseline-json]}"
baseline_json="${2:-ci/baselines/simulator-app-size.json}"
label="${3:-httpjpg.app_kb}"

if [[ ! -f "$baseline_json" ]]; then
  echo "No baseline at $baseline_json — measured ${size_kb} KiB"
  exit 0
fi

floor=$(python3 - "$baseline_json" "$label" <<'PY'
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
val = data.get(key)
print("" if val is None else val)
PY
)

{
  echo "### Simulator app size"
  echo ""
  echo "| | KiB |"
  echo "| --- | ---: |"
  echo "| measured | ${size_kb} |"
  if [[ -n "$floor" ]]; then
    delta=$((size_kb - floor))
    if [[ "$floor" -gt 0 ]]; then
      pct=$(python3 -c "print(f'{($size_kb - $floor) * 100 / $floor:.1f}')")
    else
      pct="n/a"
    fi
    echo "| baseline | ${floor} |"
    echo "| delta | ${delta} (${pct}%) |"
  else
    echo "| baseline | _(unset)_ |"
  fi
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

if [[ -z "$floor" ]]; then
  echo "Baseline unset — measured ${size_kb} KiB (record with scripts/record-app-size-baseline.sh)"
  exit 0
fi

python3 - "$size_kb" "$floor" <<'PY'
import sys
size, floor = int(sys.argv[1]), int(sys.argv[2])
if floor <= 0:
    print(f"Baseline {floor} is unusable — measured {size} KiB")
    sys.exit(0)
delta = size - floor
pct = delta * 100 / floor
print(f"measured {size} KiB vs baseline {floor} KiB ({pct:+.1f}%)")
if pct >= 10:
    print(f"::error::Simulator .app grew {pct:.1f}% (≥10%). Update the baseline if intentional.")
    sys.exit(1)
if pct >= 5:
    print(f"::warning::Simulator .app grew {pct:.1f}% (≥5%).")
sys.exit(0)
PY
