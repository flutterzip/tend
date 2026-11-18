#!/bin/bash
# Records a scripted run on the simulator: tool/rec.sh book
# Writes build/rec/<reel>.mov. The recorder only writes its file on SIGINT,
# and a background job in a script ignores SIGINT from `kill`, so it is
# stopped with pkill.
cd "$(dirname "$0")/.."
REEL=${1:-signIn}
DEV=${TEND_DEVICE:-44CDDB86-D61F-47C8-8C65-7C87828A38C5}
OUT="$PWD/build/rec/$REEL.mov"
mkdir -p build/rec
rm -f "$OUT"
# Build and install first, so the recorder is not started mid-install.
flutter build ios --simulator --debug -t integration_test/showreel_test.dart > build/rec/$REEL.build.log 2>&1
for try in 1 2 3; do
  xcrun simctl io "$DEV" recordVideo --codec h264 --force "$OUT" > build/rec/$REEL.rec.log 2>&1 &
  sleep 2
  grep -q "Recording started" build/rec/$REEL.rec.log && break
  echo "recorder did not start (try $try)"; sleep 2
done
flutter drive -d "$DEV" --driver test_driver/integration_test.dart \
  --target integration_test/showreel_test.dart --dart-define=reel=$REEL > build/rec/$REEL.log 2>&1
pkill -INT -f "recordVideo.*$OUT"
for i in $(seq 1 30); do grep -q "Wrote video" build/rec/$REEL.rec.log && break; sleep 1; done
tail -1 build/rec/$REEL.rec.log
