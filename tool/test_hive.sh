#!/bin/bash
set -eu

cd hive

pub get
pub run test -p "$TEST_PLATFORM"

dartfmt -n --set-exit-if-changed ./lib ./test ./example || exit 1
