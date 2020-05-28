#!/bin/zsh
mkdir -p certificate/
cd certificate/

cat <<EOF > ca.cnf
[ca]
default_ca = CA_default

[CA_default]
new_certs_dir = ./new_certs
database = ./index.txt
serial   = ./serial.dat

private_key = ca.key.pem
certificate = ca.cert.pem

policy = policy_catapult

[policy_catapult]
commonName              = supplied

[req]
prompt = no
distinguished_name = dn

[dn]
CN = cat-ca-superhow
EOF

cat <<EOF > node.cnf
[req]
prompt = no
distinguished_name = dn

[dn]
CN = cat-node-superhow
EOF

mkdir new_certs && chmod 700 new_certs
touch index.txt

# create CA serial
openssl rand -hex 19 > ./serial.dat

# create CA key
openssl genpkey -out ca.key.pem -outform PEM -algorithm ed25519
openssl pkey -inform pem -in ca.key.pem -text -noout
openssl pkey -in ca.key.pem -pubout -out ca.pubkey.pem

# create CA cert and self-sign it
openssl req -config ca.cnf -keyform PEM -key ca.key.pem -new -x509 -days 7300 -out ca.cert.pem
openssl x509 -in ca.cert.pem  -text -noout

# create node key
openssl genpkey -out node.key.pem -outform PEM -algorithm ed25519
openssl pkey -inform pem -in node.key.pem -text -noout

# create node request
openssl req -config node.cnf -key node.key.pem -new -out node.csr.pem
openssl req -text -noout -verify -in node.csr.pem

# sign node cert for 375 days
openssl ca -config ca.cnf -days 375 -notext -in node.csr.pem -out node.crt.pem
openssl verify -CAfile ca.cert.pem node.crt.pem

# finally create full crt
cat node.crt.pem ca.cert.pem > node.full.crt.pem
cd ..
