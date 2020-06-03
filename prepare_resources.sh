#!/bin/zsh
# require zsh for associative arrays

local node_type=$1
local catapult_bin=$2
local resources_src=$3
local resources_dest=$4
local private_key=$5
local public_key=$6
local generation_hash=$7
local local_path=$PWD
local network_id=$8

function copy_peers() {
    local filename="peers-$1.json"
    echo "copying $filename"
    cp "${resources_src}/resources/${filename}" "${resources_dest}/${filename}"
}

function copy_properties() {
    local filename="config-$1.properties"
    echo "copying $filename"
    cp "${resources_src}/resources/${filename}" "${resources_dest}/${filename}"
}

function run_sed() {
    local filename="config-$1.properties"
    echo "updating $filename"
    
    # using "#" for delimiters so as to be friendly to paths
    for key value in ${(kv)${(P)2}}; do
        sed -i -e "s#$key =.*#$key = $value#;" ${resources_dest}/${filename}
        echo "DONE sed file in $key $value $1 $2 $filename"
    done
}

function set_extensions() {
    local filename="config-$1.properties"
    echo "updating extensions in $filename"
    
    for key in ${(k)${(P)3}}; do
        sed -i -e "s/extension.$key = .*/extension.$key = $2/;" ${resources_dest}/${filename}
        echo "DONE setting extension in $key $1 $2 $3"
    done
}

function prepare_base_resources() {
    echo
    echo "Starting preparing BASE resources."
    echo
    copy_peers "p2p"
    
    for extension in "extensions-server" "inflation" "logging-recovery" "extensions-recovery" "logging-server" "network" "networkheight" "node" "task" "timesync" "user"; do
        copy_properties $extension
    done
    
    local -A logging_pairs=(
            "level" "Debug"
            "sinkType" "Async")
    run_sed "logging-server" logging_pairs
    
    local -A node_pairs=(
            "unconfirmedTransactionsCacheMaxSize" "10'000'000"
            "connectTimeout" "15s"
            "syncTimeout" "120s"
            "defaultBanDuration" "0h")
    run_sed "node" node_pairs
        
    local -A network_pairs=(
            "identifier" "$network_id"
            "publicKey" "$public_key"
            "generationHashSeed" "$generation_hash"
            "initialCurrencyAtomicUnits" "1'079'999'998'000'000"
            "totalChainImportance" "36'000'000"
            "maxHarvesterBalance" "50'000'000"
            "maxTransactionsPerAggregate" "10'000"
            "maxCosignaturesPerAggregate" "250"
            "maxCosignatoriesPerAccount" "250"
            "maxCosignedAccountsPerAccount" "100'000"
            "maxNamespaceDuration" "3650d")
    run_sed "network" network_pairs
    
    local -A user_pairs=(
            "certificateDirectory" "${local_path}/certificate"
            "dataDirectory" "${local_path}/data"
            "pluginsDirectory" "${catapult_bin}/bin")
    run_sed "user" user_pairs
}

function prepare_api_resources() {
    copy_peers "api"
    
    for extension in "extensions-broker" "logging-broker" "database" "messaging" "pt"; do
        copy_properties $extension
    done
    
    local -A logging_pairs=(
            "level" "Debug"
            "sinkType" "Async")
    run_sed "logging-broker" logging_pairs
    
    local -A node_pairs=(
            "enableAutoSyncCleanup" "false"
            "friendlyName" "friendly_api_node"
            "roles" "Api")
    run_sed "node" node_pairs
    
    local api_extensions=("filespooling" "partialtransaction")
    local p2p_extensions=("harvesting" "syncsource")
    local recovery_extensions=("addressextraction" "mongo" "zeromq")
    
    set_extensions "extensions-server" "true" api_extensions
    set_extensions "extensions-server" "false" p2p_extensions
    set_extensions "extensions-recovery" "true" recovery_extensions
}

function prepare_peer_resources() {
    for extension in "harvesting"; do
        copy_properties $extension
    done
    
    local -A node_pairs=(
            "enableSingleThreadPool" "true"
            "enableDispatcherAbortWhenFull" "false"
            "enableDispatcherInputAuditing" "false"
            "friendlyName" "friendly_peer_node"
            "roles" "Peer"
            "numConsecutiveFailuresBeforeBanning" "6")
    run_sed "node" node_pairs
    
    local -A harvesting_pairs=(
            "harvesterPrivateKey" "HARVESTER_PRIVATE_KEY"
            "enableAutoHarvesting" "true")
    run_sed "harvesting" harvesting_pairs
}

function prepare_dual_resources() {
    local -A node_pairs=(
            "enableSingleThreadPool" "false"
            "enableDispatcherAbortWhenFull" "true"
            "enableDispatcherInputAuditing" "false"
            "friendlyName" "friendly_dual_node"
            "roles" "Api, Peer")
    run_sed "node" node_pairs
    
    local p2p_extensions=("harvesting" "syncsource")
    set_extensions "extensions-server" "true" p2p_extensions
}

echo "[PREPARING $node_type NODE CONFIGURATION]"
echo
prepare_base_resources
echo
echo "Finished preparing BASE resources."
echo

case "$node_type" in
    api)
        prepare_api_resources
        echo
        echo "Prepared API resources."
        echo
    ;;
    
    peer)
        prepare_peer_resources
        echo
        echo "Prepared PEER resources."
        echo
    ;;
    
    dual)
        prepare_api_resources
        prepare_peer_resources
        prepare_dual_resources
        echo
        echo "Prepared DUAL resources."
        echo
    ;;
    *)
        echo
        echo "Prepared NOTHING!."
        echo
    ;;
esac
