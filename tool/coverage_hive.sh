#!/bin/bash

# Fast fail the script on failures.
set -e

cd hive

pub get
pub global activate test_coverage

pub global run test_coverage --exclude "**_js_test.dart"