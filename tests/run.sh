#!/usr/bin/env bash
# Alle Spieltests headless ausfuehren. Godot-Pfad per GODOT ueberschreibbar.
set -o pipefail
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1
# class_name-Skripte (neu) registrieren, sonst kennt --script sie nicht
"$GODOT" --headless --path . --import >/dev/null 2>&1
status=0
for t in tests/test_*.gd; do
	echo "== $t"
	# Zeitlimit je Test (macOS hat kein timeout): Wachhund beendet haengende Laeufe
	tmp=$(mktemp)
	"$GODOT" --headless --path . --script "res://$t" >"$tmp" 2>&1 &
	pid=$!
	( sleep "${TEST_TIMEOUT:-120}"; kill -9 "$pid" 2>/dev/null && echo "ZEITLIMIT ueberschritten" >>"$tmp" ) &
	dog=$!
	wait "$pid"
	code=$?
	kill "$dog" 2>/dev/null
	wait "$dog" 2>/dev/null
	out=$(cat "$tmp")
	rm -f "$tmp"
	echo "$out" | grep -E "^(  |[0-9]+/|[A-Z])"
	# Parse-/Laufzeitfehler oder fehlende Abschlusszeile zaehlen als Fehlschlag
	if [ $code -ne 0 ] || ! echo "$out" | grep -q "Pruefungen bestanden"; then
		status=1
	fi
done
exit $status
