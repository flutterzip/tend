#!/bin/bash
# Screenshots of every screen on the simulator, light then dark, to
# build/shots/. Stop tool/run.sh first.
cd "$(dirname "$0")/.."
DEV=${TEND_DEVICE:-44CDDB86-D61F-47C8-8C65-7C87828A38C5}
xcrun simctl status_bar "$DEV" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null 2>&1
for mode in light dark; do
  flutter drive -d "$DEV" --driver test_driver/shots_driver.dart --target integration_test/shots_test.dart \
    --dart-define=mode=$mode > build/shots_$mode.log 2>&1 && echo "$mode done" || { echo "$mode failed"; tail -20 build/shots_$mode.log; }
done
xcrun simctl status_bar "$DEV" clear >/dev/null 2>&1
ls build/shots
