#!/bin/bash

# Fast fail the script on failures.
set -e

cd hive

alias google-chrome=google-chrome-stable

if [ -z "$TEST_PLATFORM" ]; then
  TEST_PLATFORM="vm"
fi

pub get
pub run test -p "$TEST_PLATFORM"

dartfmt -n --set-exit-if-changed ./lib ./test ./example || exit 1
