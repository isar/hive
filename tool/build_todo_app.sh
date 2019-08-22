#!/bin/bash

# Fast fail the script on failures.
set -e

cd examples/todo_app

export FLUTTER_WEB=true

flutter build web --release

git clone -b gh-pages https://github.com/leisim/hive

rm -rf hive/demo
cp -R build/web hive/demo

cd hive

git config --global user.email "<>"
git config --global user.name "hivebot"

git add -A
git diff-index --quiet HEAD || git commit -m "Todo App build"
git push "https://${PUSH_TOKEN}@github.com/leisim/hive.git"