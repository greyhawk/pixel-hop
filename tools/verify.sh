#!/usr/bin/env bash
set -uo pipefail
GODOT="${GODOT:-godot}"
LOG=build/logs; mkdir -p "$LOG"
fail=0

echo "== 0. level reachability (python) =="
( cd tools && python3 verify_levels.py ) 2>&1 | tee "$LOG/levels.log"
[ "$(grep -c 'REACHABLE;' "$LOG/levels.log")" -eq 3 ] && ! grep -q 'NOT reachable' "$LOG/levels.log" || { echo "FAIL levels"; fail=1; }

echo "== 0b. font presence (warn only, never fails) =="
if [ -f assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf ] && [ -f assets/fonts/OFL.txt ]; then
  echo "font present"
else
  echo "WARN: Fusion Pixel font or OFL.txt missing; UI uses the default font (see §6.3)"
fi

echo "== 0c. placeholder generator self-check (size + palette) =="
python3 tools/gen_placeholders.py 2>&1 | tee "$LOG/gen.log"
grep -q "all 28 files OK" "$LOG/gen.log" || { echo "FAIL gen_placeholders self-check"; fail=1; }

echo "== 1. import =="
"$GODOT" --headless --path . --import 2>&1 | tee "$LOG/import.log"
grep -q "SCRIPT ERROR" "$LOG/import.log" && { echo "FAIL import"; fail=1; }

# No standalone `--check-only -s` pass: it cannot see autoload singletons
# (Game/Audio/Transition) and false-fails every script that references them.
# Every .gd file is compiled in a real autoload context by steps 3-5 below
# (GUT loads the test scripts, smoke_run loads game/audio/transition/main,
# boot loads the title screen), so any compile error fails the run there.

echo "== 3. GUT 9.7.1 =="
"$GODOT" --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd \
  -gdir=res://test -ginclude_subdirs -gexit -gjunit_xml_file=res://test_results.xml 2>&1 | tee "$LOG/gut.log"
gut_rc=${PIPESTATUS[0]}
[ $gut_rc -ne 0 ] && { echo "FAIL gut rc=$gut_rc"; fail=1; }
grep -q "SCRIPT ERROR" "$LOG/gut.log" && { echo "FAIL gut script error"; fail=1; }
grep -qE 'failures="[1-9]' test_results.xml 2>/dev/null && { echo "FAIL gut junit"; fail=1; }

echo "== 4. scripted smoke run =="
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 3600 test/smoke/smoke_run.tscn 2>&1 | tee "$LOG/smoke.log"
grep -q "SCRIPT ERROR" "$LOG/smoke.log" && { echo "FAIL smoke: SCRIPT ERROR"; fail=1; }
grep -q "SMOKE OK" "$LOG/smoke.log" || { echo "FAIL smoke: no SMOKE OK"; fail=1; }

echo "== 5. main scene boot =="
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 300 2>&1 | tee "$LOG/boot.log"
grep -q "SCRIPT ERROR" "$LOG/boot.log" && { echo "FAIL boot: SCRIPT ERROR"; fail=1; }
grep -q "MAIN BOOT OK" "$LOG/boot.log" || { echo "FAIL boot: title screen never loaded"; fail=1; }

[ $fail -eq 0 ] && echo "VERIFY PASS" || echo "VERIFY FAIL"
exit $fail
