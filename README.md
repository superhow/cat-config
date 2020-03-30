# Catapult Configuration Scripts
Symbol Catapult configuration scripts by SUPER HOW? This is a set of bash scripts that aid in configuring nd launching the Symbol Catapult network. 

## Script Package Organization
cat-config scripts are organized as follows:

| Script name | Description |
| -------------|--------------|
| reset.sh | Symbol Catapult server with dependancies install script. |
| generate_hash.sh | Symbol Catapult server with dependancies install script. |

## Scripts usage

[ ] Get the scripts:  

``wget https://github.com/superhow/cat-install/raw/master/src/install_base_deps.sh``

``wget https://github.com/superhow/cat-install/raw/master/src/install_cat_deps.sh``

``wget https://github.com/superhow/cat-install/raw/master/src/install_catapult.sh``

[ ] Configuration script launch details:

``zsh scripts/cat-config/reset.sh <network_type> <node_type> <path_to_catapult_bin> <private_key> <public_key> <optional_template>``

Let's break this down:

    <node_type> - This argument tells the script which kind of node to configure. There are three node types in catapult: dual, peer, and api. An explanation for each can be found in #concepts.

    <path_to_catapult_bin> - The FULL path to your catapult-server directory on your machine. Path to where built binaries are i.e. ~/catapult/.

    <private_key> - Server node's new private key or Nemesis new private key in case of new chain.

    <public_key> - Existing network public key or Nemesis new public key in case of new chain.

    <network_option> - This tells the script how to configure the node and network (local, foundation, existing):

    'local' - zsh scripts/cat-config/reset.sh --local <node_type> <path_to_catapult_bin> <private_key> <public_key>. This starts a new chain in independent local node. It has its own new generation hash.

    'foundation' - to connect to official NEM foundation network

    'existing' - zsh scripts/cat-config/reset.sh existing <node_type> <path_to_catapult_bin> <private_key> <network_public_key> <template_name>. Resources are loaded from template to join an existing network. You may add your own template by copying the structure in templates/testnet.

## Symbol server
Symbol-based networks rely on nodes to provide a trustless, high-performance, and secure blockchain platform.
These nodes are deployed using [symbol-server] software, a C++ rewrite of the previous Java-written [NEM] distributed ledger that has been running since 2015.

## License
Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the [GNU Lesser General Public License v3](LICENSE)
This repository might include copyrighted material from Jaguar0625, gimre, BloodyRookie, Tech Bureau, Corp licensed under the [GNU Lesser General Public License v3](LICENSE)

[symbol-server]: https://github.com/nemtech/catapult-server
[symbol-rest]: https://github.com/nemtech/catapult-rest
[nem]: https://nem.io
