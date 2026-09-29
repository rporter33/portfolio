#!/usr/bin/env bash
# Run the headless test suite. Fails on any test failure *or* any script
# error, since a GDScript runtime error aborts a test method without failing it.
#
#   GODOT=/path/to/godot tools/run_tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
out="$("$GODOT" --headless --path . -s res://tests/run_tests.gd 2>&1)" && status=0 || status=$?
echo "$out"
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" <<<"$out"; then
	echo "Script errors during the test run — failing." >&2
	exit 1
fi
exit "$status"
