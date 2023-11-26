#!/bin/bash

# Generate a self-signed X.509 v3 certificate with a created CA

set -e 

# CA details
ca_country="NL"
ca_state=""
ca_locality=""
ca_organization="theautomation"
ca_organizational_unit="theautomation"
ca_common_name="theautomation Root CA"

# Certificate details
country="NL"
state=""
locality=""
organization="theautomation"
organizational_unit="theautomation"
common_name="*.lan.theautomation.nl"
email="ssl@theautomation.nl"

# Output filenames
ca_private_key_file="ca_private.key"
ca_certificate_file="ca_certificate.crt"
private_key_file="server_private.key"
certificate_file="server_certificate.crt"
v3_ext_file="v3.ext"

# Generate CA private key
openssl genrsa -out "$ca_private_key_file" 4096

# Generate CA self-signed certificate
openssl req -x509 -new -nodes -sha512 -days 11850 -subj "/C=$ca_country/ST=$ca_state/L=$ca_locality/O=$ca_organization/OU=$ca_organizational_unit/CN=$ca_common_name" \
    -key "$ca_private_key_file" \
    -out "$ca_certificate_file"

# Generate private key
openssl genrsa -out "$private_key_file" 4096

# Generate certificate signing request (CSR)
openssl req -sha512 -new -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizational_unit/CN=$common_name/emailAddress=$email" \
    -out "certificate.csr" \
    -key "$private_key_file"
    
# Create v3.ext file with Subject Alternative Name (SAN) and x509 v3 extensions
cat > "$v3_ext_file" <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$common_name
EOF

# Generate self-signed certificate using CA private key and certificate
openssl x509 -req -in "certificate.csr" -CA "$ca_certificate_file" -CAkey "$ca_private_key_file" -CAcreateserial -out "$certificate_file" -days 11850 -sha256

# Clean up the CSR and CA serial files
rm "certificate.csr"
rm "$v3_ext_file"

# Print the generated certificates information
echo "Root CA Certificate:"
openssl x509 -in "$ca_certificate_file" -text -noout
echo ""
echo "Self-Signed Certificate:"
openssl x509 -in "$certificate_file" -text -noout
