#!/bin/zsh
# generates the nemesis block properties file and nemesis block

local catapult_bin=$1
local nemesis_signer_key=$2
local generation_hash=$3
local network_type=$4
local nemesis_path="/nemesis/nemesis-block.properties"
local harvester_keys_path="harvester_addresses.txt"
local currency_keys_path="currency_addresses.txt"
local local_path=$PWD

### From catapult-service-bootstrap
config_form() {
    local split=$(echo $1 | sed 's/\(.\)/\1 /g')
    local concat=$(printf "%c%c%c%c'" $(echo $split))
    echo "0x$concat[1,-2]"
}

function generate_addresses() {
    local no_of_keys=$1
    local destination=$2
    echo "generating addresses"
    ${catapult_bin}/bin/catapult.tools.address -n "${network_type}" -g "${no_of_keys}" > "${destination}"
}

function run_sed() {
    local filename="$1.properties"
    echo "updating properties file"
    for key value in ${(kv)${(P)2}}; do
        sed -i -e "s#$key =.*#$key = $value#;" ${local_path}${nemesis_path}
    done
}

function sed_keys() {
    sed -i -e "/\[$1\]/,/^\[/ s/$2/$3/g" ${local_path}${nemesis_path}
}

function update_nemesis_block_file() {
#    cp "${catapult_bin}/tools/nemgen/resources/mijin-test.properties" ${local_path}${nemesis_path}
    cp "${catapult_bin}/scripts/cat-config/resources/mijin-test.properties" ${local_path}${nemesis_path}
    
    local -A nemesis_pairs=(
            "networkIdentifier" "${network_type}"
            "cppFile" ""
            "nemesisGenerationHash" "$generation_hash"
            "nemesisSignerPrivateKey" "$nemesis_signer_key"
            "binDirectory" "${local_path}/seed")
    run_sed "nemesis-block" nemesis_pairs
    update_keys
}

function update_keys() {
# Keys for ${network_type} network
    generate_addresses 23 ${currency_keys_path}
    generate_addresses 11 ${harvester_keys_path}
    
    if [[ ! -a $harvester_keys_path ]] then;
        echo "addresses file not generated"
        return 0;
    fi

# Keys for mijin-test network    
#    local new_harvester_addresses=( $(grep S $harvester_keys_path | sed -e 's/address (mijin-test)://g') )
#    local old_harvester_addresses=( $(grep -i -A12 "\bdistribution>cat:harvest\b" "${local_path}${nemesis_path}" | grep -o -e "^S.\{40\}") )
    
#    local new_currency_addresses=( $(grep S $currency_keys_path | sed -e 's/address (mijin-test)://g') )
#    local old_currency_addresses=( $(grep -i -A24 "\bdistribution>cat:currency\b" "${local_path}${nemesis_path}" | grep -o -e "^S.\{40\}") )

# Keys for ${network_type} network
    local new_harvester_addresses=( $(grep M $harvester_keys_path | sed -e 's/address (${network_type})://g') )
    local old_harvester_addresses=( $(grep -i -A12 "\bdistribution>cat:harvest\b" "${local_path}${nemesis_path}" | grep -o -e "^M.\{40\}") )
    
    local new_currency_addresses=( $(grep M $currency_keys_path | sed -e 's/address (${network_type})://g') )
    local old_currency_addresses=( $(grep -i -A24 "\bdistribution>cat:currency\b" "${local_path}${nemesis_path}" | grep -o -e "^M.\{40\}") )
    
    ## replace the harvester addresses
    for i in {1..11}
    do
        sed_keys "distribution>cat:harvest" $old_harvester_addresses[$i] $new_harvester_addresses[$i]
    done
    
    ## then replace the currency addresses
    for i in {1..22}
    do
        sed_keys "distribution>cat:currency" $old_currency_addresses[$i] $new_currency_addresses[$i]
    done
}

function nemgen() {
    update_nemesis_block_file
    
####### Nemgen script part from https://github.com/tech-bureau/catapult-service-bootstrap

    if [ ! -d ${local_path}/data ]; then
        echo "/data directory does not exist"
        exit 1
    fi
    
    if [ ! -d ${local_path}/data/00000 ]; then
        echo "running nemgen"
        mkdir settings
        mkdir -p ${local_path}/seed/00000
        dd if=/dev/zero of=${local_path}/seed/00000/hashes.dat bs=1 count=64
        cd settings

######## need to run twice and patch the mosaic id's
# first time to get cat.harvest and cat.currency
        ${catapult_bin}/bin/catapult.tools.nemgen --resources ${local_path} --nemesisProperties "${local_path}${nemesis_path}" 2> /tmp/nemgen.log
        local harvesting_mosaic_id=$(grep "cat.harvest" /tmp/nemgen.log | grep nonce | awk -F= '{split($0, a, / /); print a[9]}' | sort -u)
        local currency_mosaic_id=$(grep "cat.currency" /tmp/nemgen.log | grep nonce | awk -F= '{split($0, a, / /); print a[9]}' | sort -u)
        
# second time after replacing values for currencyMosaicId and harvestingMosaicId
        sed -i -e "s/^harvestingMosaicId\ .*/harvestingMosaicId = $(config_form ${harvesting_mosaic_id})/" "${local_path}/resources/config-network.properties"
        sed -i -e "s/^currencyMosaicId\ .*/currencyMosaicId = $(config_form ${currency_mosaic_id})/" "${local_path}/resources/config-network.properties"

        ${catapult_bin}/bin/catapult.tools.nemgen --resources ${local_path} --nemesisProperties "${local_path}${nemesis_path}" 2> $local_path/tmp/nemgen2.log
        cp -r ${local_path}/seed/* ${local_path}/data/
        cd ..
    else
        echo "no need to run nemgen"
    fi
}

nemgen
