#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export PROJECT_DIR="${SCRIPT_DIR}/.."

mkdir "${PROJECT_DIR}/${1}"

pushd "${PROJECT_DIR}/${1}"

DNS_SUFFIX=envs.cfplatformeng.com

"${SCRIPT_DIR}/gen-cert.sh" "${1}.${DNS_SUFFIX}" > /dev/null

SSL_CERT=$(cat "${1}.${DNS_SUFFIX}.crt")
SSL_KEY=$(cat "${1}.${DNS_SUFFIX}.key")

cat > ./terraform.tfvars <<EOF
subscription_id = "${ARM_SUBSCRIPTION_ID}"
tenant_id       = "${ARM_TENANT_ID}"
client_id       = "${ARM_CLIENT_ID}"
client_secret   = "${ARM_CLIENT_SECRET}"

env_name              = "${1}"
ops_manager_image_uri = "https://opsmanagerwestus.blob.core.windows.net/images/ops-manager-2.9.1-build.121.vhd"
#ops_manager_image_uri = "https://opsmanagerwestus.blob.core.windows.net/images/ops-manager-2.8.8-build.266.vhd"
location              = "West US 2"
dns_suffix            = "${DNS_SUFFIX}"

dns_subdomain         = ""

ssl_cert = <<SSL_CERT
${SSL_CERT}
SSL_CERT

ssl_private_key = <<SSL_KEY
${SSL_KEY}
SSL_KEY
EOF

cp ../terraforming-pas/*.tf .

popd