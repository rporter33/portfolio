#!/usr/bin/env bash
# Run the headless test suite and the smoke playthrough. Fails on any test
# failure *or* any script error, since a GDScript runtime error aborts a test
# method (or a draw call) without failing anything by itself.
#
#   GODOT=/path/to/godot tools/run_tests.sh
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
fail=0

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

check() {
	local label="$1"; shift
	local out status
	out="$("$@" 2>&1)"; status=$?
	echo "$out" | grep -v -E "^Godot Engine|^\s*$"
	if [ $status -ne 0 ]; then
		echo "✗ $label exited with $status" >&2; fail=1
	fi
	if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" <<<"$out"; then
		echo "✗ $label printed script errors" >&2; fail=1
	fi
}

check "unit tests" "$GODOT" --headless --path . -s res://tests/run_tests.gd
check "smoke playthrough" "$GODOT" --headless --path . res://tools/smoke.tscn
[ $fail -eq 0 ] && echo "✓ all green"
exit $fail
