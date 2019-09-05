#!/bin/bash
set -eu

cd hive

pub get

#dartfmt -n --set-exit-if-changed ./lib ./test || exit 1

pub run test -p "$TEST_PLATFORM"
