#!/bin/zsh

local catapult_bin=$1
local generation_path=$PWD/generation_hash.txt
local network_id=$2

## Run address tool
# ${catapult_bin}/bin/catapult.tools.address -n mijin-test -g 1 > "${generation_path}"
${catapult_bin}/bin/catapult.tools.address -n ${network_id} -g 1 > "${generation_path}"
