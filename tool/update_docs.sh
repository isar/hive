#!/bin/bash

# Fast fail the script on failures.
set -e

git clone -b gh-pages https://github.com/leisim/hive pages

cd pages

rm -f *.md
cp ../docs/* .

git config --global user.email "<>"
git config --global user.name "hivebot"

git add -A
git diff-index --quiet HEAD || git commit -m "Update docs"
git push "https://${PUSH_TOKEN}@github.com/leisim/hive.git"