#!/bin/bash
# Six devices; each runs the same four journeys in portrait and landscape, plus importer tests.
set -uo pipefail
scripts_dir="$(cd "$(dirname "$0")" && pwd)"
matrix_dir="${MATRIX_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/pecs-picker-matrix.XXXXXX")}"
mkdir -p "$matrix_dir"
failed=0
for version in 18-4 26-5 27-0; do
  for family in iPhone iPad; do
    case "$version/$family" in
      18-4/iPhone) device=iPhone-16 ;;
      18-4/iPad) device=iPad-Pro-11-inch-M4-8GB ;;
      */iPhone) device=iPhone-17 ;;
      */iPad) device=iPad-Pro-11-inch-M5-12GB ;;
    esac
    run_dir="$matrix_dir/$version-$family"
    echo "Testing iOS $version $family, portrait and landscape: $run_dir"
    if RUN_DIR="$run_dir" RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-$version" \
       DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.$device" \
       "$scripts_dir/test.sh" > "$matrix_dir/$version-$family.log" 2>&1; then
      echo "PASS: iOS $version $family"
    else
      echo "FAIL: iOS $version $family; inspect $matrix_dir/$version-$family.log" >&2
      failed=1
    fi
  done
done
echo "Matrix results: $matrix_dir"
exit "$failed"
