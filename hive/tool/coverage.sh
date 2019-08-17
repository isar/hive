#!/bin/bash

# Fast fail the script on failures.
set -e

# Gather coverage and upload to Coveralls.
if [ "$CODECOV_TOKEN" ] then
  OBS_PORT=9292
  echo "Collecting coverage on port $OBS_PORT..."

  pub get
  pub global activate coverage

  # Start tests in one VM.
  dart --disable-service-auth-codes \
    --enable-vm-service=$OBS_PORT \
    --pause-isolates-on-exit \
    test/test_all.dart &

  # Run the coverage collector to generate the JSON coverage report.
  collect_coverage \
    --port=$OBS_PORT \
    --out=var/coverage.json \
    --wait-paused \
    --resume-isolates

  echo "Generating LCOV report..."
  format_coverage.dart \
    --lcov \
    --in=var/coverage.json \
    --out=var/lcov.info \
    --packages=.packages \
    --report-on=lib

  bash <(curl -s https://codecov.io/bash)
fi