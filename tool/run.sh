#!/bin/bash
# Runs Tend on the iPhone 17 Pro Max simulator, stdin on a FIFO:
#   echo r > /tmp/tend/fifo   hot reload     (R restart, q quit)
# The FIFO lives outside the project: a pipe inside it hangs `flutter build`.
# Extra arguments go to `flutter run` (for example --dart-define=startRoute=signIn).
cd "$(dirname "$0")/.."
mkdir -p /tmp/tend
rm -f /tmp/tend/fifo
mkfifo /tmp/tend/fifo
sleep 100000 > /tmp/tend/fifo &
HOLD=$!
trap 'kill $HOLD 2>/dev/null' EXIT
flutter run -d "${TEND_DEVICE:-44CDDB86-D61F-47C8-8C65-7C87828A38C5}" "$@" < /tmp/tend/fifo > /tmp/tend/run.log 2>&1
