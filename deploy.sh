#!/bin/bash
if [ -z "$(git status --porcelain)" ]; then 
  # Working directory clean

jq -M ".version=\"$1\"" config.json > config.swap.json
cat config.swap.json > config.json
rm -f config.swap.json

git add config.json
git commit -m "$1"
git tag -afm "$1"

dome nest -c res *.wren
mv game.egg ../dome-builds/acolytes-pledge
cp config.json ../dome-builds/acolytes-pledge
cd ../dome-builds/acolytes-pledge
./upload-all.sh $1 $2
else 
  echo "There are uncommitted changes, please commit first."
  # Uncommitted changes
fi
