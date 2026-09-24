#!/bin/bash
set -euo pipefail
harness_dir="$(cd "$(dirname "$0")/.." && pwd)"
run_dir="${RUN_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/pecs-picker-tests.XXXXXX")}"
mkdir -p "$run_dir"
state="$run_dir/simulator.json"
if [[ -e "$state" || -e "$run_dir/Tests.xcresult" ]]; then
  echo "Refusing to reuse a run directory with simulator state or test results: $run_dir" >&2
  exit 1
fi
cleanup() {
  if [[ "${KEEP_SIM:-0}" != 1 && -f "$state" ]]; then
    python3 "$harness_dir/Scripts/simulator.py" delete --state "$state"
  fi
}
trap cleanup EXIT
echo "Results and simulator ownership: $run_dir"
python3 "$harness_dir/Scripts/simulator.py" create --state "$state" \
  --runtime "${RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-5}" \
  --device-type "${DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17}" > "$run_dir/udid.txt"
udid="$(cat "$run_dir/udid.txt")"
xcodebuild -version | tee "$run_dir/xcode-version.txt"
xcrun simctl list runtimes -j > "$run_dir/runtimes.json"
echo "Results: $run_dir"
xcodebuild -project "$harness_dir/PhotoPickerHarness.xcodeproj" -scheme PhotoPickerHarness \
  -destination "platform=iOS Simulator,id=$udid" -parallel-testing-enabled NO \
  -derivedDataPath "$run_dir/DerivedData" -resultBundlePath "$run_dir/Tests.xcresult" \
  test "$@" 2>&1 | tee "$run_dir/test.log"
