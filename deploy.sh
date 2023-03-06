#!/bin/bash

CONTENT=$(jq ".version=\"$1\"" config.json)
echo $CONTENT > config.json

dome nest -c *.wren config.json
mv game.egg ../dome-builds/acolytes-pledge
cd ../dome-builds/acolytes-pledge
./upload-all.sh $1
