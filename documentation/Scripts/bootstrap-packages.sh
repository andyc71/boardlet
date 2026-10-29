#!/bin/bash
set -euo pipefail
# Clone only missing sibling packages; never alter existing checkouts.
dev_dir="$(cd "$(dirname "$0")/../../.." && pwd)"
for package in SystemPhotoPicker VoicePickerUI BoardLibrary AACStandardSymbols ARASAACSymbols OpenSymbols EngagementKit MediaFramework; do
  if [[ ! -e "$dev_dir/$package" ]]; then
    git clone "https://github.com/andyc71/$package.git" "$dev_dir/$package"
  elif [[ ! -f "$dev_dir/$package/Package.swift" ]]; then
    echo "Expected a Swift package at $dev_dir/$package" >&2
    exit 1
  fi
done
