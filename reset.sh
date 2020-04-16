#!/bin/zsh

local network_type=$1
local node_type=$2
local catapult_bin=$3
local private_key=$4
local public_key=$5
local template=$6
local network_id=mijin
local script_src=$PWD/scripts/cat-config

if [[ -z "${network_type}" ]] then;
    echo "script must be called with one of the three network options: private | existing | symbol"
    return 0
    
    elif [[ -z "${node_type}" ]] then;
    echo "script must be called with one of the three node types: api | peer | dual"
    return 0
fi

echo
echo "Welcome to the Catapult Config Utility"
echo
echo "network_type = ${network_type}"
echo "node_type = ${node_type}"
echo "catapult_bin = ${catapult_bin}"
echo "private_key = ${private_key}"
echo "public_key = ${public_key}"
echo "template = ${template}"
echo "network_id = ${network_id}"
echo "script_src = ${script_src}"
echo

# reapply data directory
echo "+ preparing fresh data and seed directory"
rm -rf $PWD/data
rm -rf $PWD/seed
mkdir $PWD/data
mkdir $PWD/seed

# clear state directories
rm -rf state
rm -rf statedb

echo
echo "<<< DONE"
echo

# reset mongo
if [[ "peer" != "${node_type}" ]] then;
    echo
    echo "+ resetting mongo"
    pushd .
    source ${script_src}/reset_mongo.sh ${catapult_bin}
    popd
    echo
    echo "<<< DONE"
    echo
fi

# clear logs
echo "+ clearing logs"
touch catapult_server.reset.log # suppress glob errors by creating a file that always matches the glob
rm -f *.log
rm -rf logs

# recreate resources
echo "+ recreating resources"
rm -rf $PWD/resources
rm -rf $PWD/nemesis
mkdir $PWD/resources
mkdir $PWD/nemesis

function setup_existing() {
    local generation_hash=$(grep "private key:" ${script_src}/templates/${template}/generation_hash.txt | sed 's/private key://g' | tr -d ' ')
    
    echo
    echo "${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/${template} $PWD/resources ${private_key} ${public_key} ${generation_hash}"
    source ${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/${template} $PWD/resources ${private_key} ${public_key} ${generation_hash}
    cp -R ${script_src}/templates/${template}/seed/* $PWD/data
}

function setup_private() {
    
    echo
    echo "Generating network generation hash (UUID) for Catapult private network"
    echo
    echo "${script_src}/generate_hash.sh ${catapult_bin} ${network_id}"
    source ${script_src}/generate_hash.sh ${catapult_bin} ${network_id}
    local generation_hash=$(grep "private key:" $PWD/generation_hash.txt | sed 's/private key://g' | tr -d ' ')
    echo
    echo "Generetion hash is: ${generation_hash}"
    echo
    
    echo
    echo "Preparing resources"
    echo
    echo "${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/private $PWD/resources ${private_key} ${public_key} ${generation_hash} ${network_id}"
    echo
    source ${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/private $PWD/resources ${private_key} ${public_key} ${generation_hash} ${network_id}
    
    echo
    echo "Generating new nemesis block"
    echo
    echo "${script_src}/prepare_nemesis_block.sh ${catapult_bin} ${private_key} ${generation_hash} ${network_id}"
    echo
    source ${script_src}/prepare_nemesis_block.sh ${catapult_bin} ${private_key} ${generation_hash} ${network_id}
}

function setup_symbol() {
    echo
    echo "Preparing Symbol public resources"
    echo
    # Generation hash and network public key from configuration for the Symbol network
    local generation_hash=CC42AAD7BD45E8C276741AB2524BC30F5529AF162AD12247EF9A98D6B54A385B
    local network_public_key=A3CE86263CD000F45867A6B5A396A521AF4557D9A6BD3C796478A9BF40BF4F4C
    echo "${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/symbol $PWD/resources ${private_key} ${network_public_key} ${generation_hash}"
    echo
    source ${script_src}/prepare_resources.sh ${node_type} ${catapult_bin} ${script_src}/templates/symbol $PWD/resources ${private_key} ${network_public_key} ${generation_hash}
    
    cp -R ${script_src}/templates/symbol/seed/* $PWD/data
    cp -R ${script_src}/templates/symbol/seed/* $PWD/seed
}

case "${network_type}" in
    ## Prepare a standalone, single private Catapult node with its own completely new network
    private)
         
        setup_private
        echo
        echo "Finished setup Catapult private network."
        echo
    ;;
    ## Prepare a node that is capable of connecting to the Symbol public network
    symbol)
        
        setup_symbol
        echo
        echo "Finished setup Symbol public."
        echo
    ;;
    ## Prepare a node that is ready to connect to an existing network
    existing)
        
        setup_existing
        echo
        echo "Finished setup existing."
        echo
    ;;
esac
