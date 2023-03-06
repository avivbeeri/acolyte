#!/bin/bash

#
#CONTENT=$(jq -r ".version=\"$1\"" config.json)
#echo $CONTENT > config.json
jq -M ".version=\"$1\"" config.json > config.swap.json
cat config.swap.json > config.json
rm -f config.swap.json

dome nest -c *.wren config.json
mv game.egg ../dome-builds/acolytes-pledge
cd ../dome-builds/acolytes-pledge
./upload-all.sh $1
