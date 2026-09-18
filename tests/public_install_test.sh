#!/usr/bin/env bash
# Fetch and exercise the exact public README input, not the working-tree script.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-public-install.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT

# Fail closed if the documented quick-start shape changes without test review.
read -r url digest < <(python3 - "$root/README.md" <<'PY'
import re
import sys
from pathlib import Path

section = Path(sys.argv[1]).read_text().split('## Quick Start\n', 1)[1]
block = section.split('```bash\n', 1)[1].split('```', 1)[0]
urls = re.findall(r'curl -fsSL (https://raw\.githubusercontent\.com/basefoundry/base-demo/[0-9a-f]{40}/install\.sh) -o install\.sh', block)
digests = re.findall(r"printf '%s  install.sh\\n' ([0-9a-f]{64}) \| shasum -a 256 -c -", block)
if len(urls) != 1 or len(digests) != 1:
    sys.exit('public bootstrap must have one exact-commit URL and SHA-256 gate')
if 'RUN_UPDATE_PROFILE=false bash install.sh' not in block:
    sys.exit('public bootstrap must explicitly opt out of profile updates')
print(urls[0], digests[0])
PY
)
curl --fail --silent --show-error --location "$url" -o "$fixture/install.sh"
printf '%s  %s\n' "$digest" "$fixture/install.sh" | shasum -a 256 -c -
chmod +x "$fixture/install.sh"
BASE_DEMO_TEST_BOOTSTRAP="$fixture/install.sh" bats "$root/tests/install_test.bats"
