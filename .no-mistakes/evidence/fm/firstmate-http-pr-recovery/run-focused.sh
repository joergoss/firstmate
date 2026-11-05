#!/usr/bin/env bash
# Load one repository behavior suite without its bottom-of-file test list, then
# run the named test in this shell so its fixture remains available as evidence.
set -u
suite=$1
marker=$2
focused_test=$3
tmp=$(mktemp "$PWD/tests/.focused-evidence.XXXXXX") || exit 1
python3 -I - "$PWD/$suite" "$tmp" "$marker" <<'PY'
from pathlib import Path
import sys
source, destination, marker = sys.argv[1:]
text = Path(source).read_text()
needle = "\n" + marker + "\n"
if text.count(needle) != 1:
    raise SystemExit(f"expected one suite marker {marker!r}, found {text.count(needle)}")
Path(destination).write_text(text.split(needle, 1)[0] + "\n")
PY
. "$tmp"
rc=$?
rm -f "$tmp"
[ "$rc" -eq 0 ] || return "$rc"
"$focused_test"
