#!/bin/bash

jq -M ".version=\"$1\"" config.json > config.swap.json
cat config.swap.json > config.json
rm -f config.swap.json

dome nest -c res *.wren
mv game.egg ../dome-builds/acolytes-pledge
cp config.json ../dome-builds/acolytes-pledge
cd ../dome-builds/acolytes-pledge
./upload-all.sh $1 $2
