#!/bin/bash
catapult_bin=$1

cd ${catapult_bin}/scripts/mongo
echo "cleaning mongo ..."
mongo catapult < mongoDbDrop.js

echo "preparing mongo ..."
mongo catapult < mongoDbPrepare.js
