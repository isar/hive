#!/bin/bash

# Fast fail the script on failures.
set -e

cd examples/$APP

export FLUTTER_WEB=true

flutter build web --release

git clone -b gh-pages https://github.com/leisim/hive

rm -rf hive/demos/$APP
cp -R build/web hive/demos/$APP

cd hive

git config --global user.email "<>"
git config --global user.name "hivebot"

git add -A
git diff-index --quiet HEAD || git commit -m "$APP build"
git push "https://${PUSH_TOKEN}@github.com/leisim/hive.git"