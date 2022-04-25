#!/bin/bash

# blockchain="eth"
# dataSource="http:\/\/34.87.241.136:8545"

if [ -z "$1" ]
  then
    echo "ERROR: Blockchain is required"
    exit 1
fi


blockchain="$1"

source .env

if [ "$blockchain" = "eth" ]
then
  PROJECT_ID=$ETH_PROJECT
  dataSource="http:\/\/34.87.241.136:8545"
elif [ "$blockchain" = "dot" ]
then
  PROJECT_ID=$DOT_PROJECT
  dataSource="https:\/\/34.116.128.226"
else
  echo "ERROR. Blockchain unspecified or invalid"
  exit 1
fi

echo "Setting up Test environment ..."
sleep 420

#-------------------------------------------
# Wait for core component to finish setup
#-------------------------------------------
echo "-----------------------------------------"
while [[ "$core_ready_response" != "200" ]] || [[ "$portal_ready_response" != "200" ]] || [[ "$rust_ready_response" != "200" ]] || [[ "$staking_ready_response" != "200" ]]; do
  core_ready_response=$(curl -o /dev/null -s -w "%{http_code}\n" --location https://dapi.massbitroute.dev/deploy/build.txt)
  echo "CORE response: $core_ready_response"
  
  rust_ready_response=$(curl -o /dev/null -s -w "%{http_code}\n" --location 'http://verify-as.massbitroute.dev/ping' )
  echo "RUST reponse: $rust_ready_response"

  portal_ready_response=$(curl -o /dev/null -s -w "%{http_code}\n" --location 'https://portal.massbitroute.dev/health-check' )
  echo "PORTAL reponse: $portal_ready_response"

  staking_ready_response=$(curl -o /dev/null -s -w "%{http_code}\n" --location  'https://staking.massbitroute.dev/health-check' )
  echo "STAKING reponse: $staking_ready_response"

  echo "-----------------------------------------"
  sleep 15
done
echo "Massbit test env setup completion: Pass"

nodePrefix="$(echo $RANDOM | md5sum | head -c 5)"

#-------------------------------------------
# Log into Portal
#-------------------------------------------
bearer=$(curl -s --location --request POST 'https://portal.massbitroute.dev/auth/login' --header 'Content-Type: application/json' \
        --data-raw "{\"username\": \"$TEST_USERNAME\", \"password\": \"$TEST_PASSWORD\"}"| jq  -r ". | .accessToken")

if [[ "$bearer" == "null" ]]; then
  echo "Getting JWT token: Failed"
  exit 1
fi


#-------------------------------------------
# create  node/gw in Portal
#-------------------------------------------
echo "Create new node and gw in Portal: In Progress"
sudo curl -s --location --request POST 'https://portal.massbitroute.dev/mbr/node' \
  --header "Authorization: Bearer  $bearer" \
  --header 'Content-Type: application/json' \
  --data-raw "{
      \"name\": \"mb-dev-node-$nodePrefix\",
      \"blockchain\": \"$blockchain\",
      \"zone\": \"AS\",
      \"dataSource\": \"$dataSource\",
      \"network\": \"mainnet\"
  }" | jq -r '. | .id, .appKey' | sed -z -z 's/\n/,/g;s/,$/,AS\n/' >nodelist.csv

sudo curl -s --location --request POST 'https://portal.massbitroute.dev/mbr/gateway' \
  --header "Authorization: Bearer  $bearer" \
  --header 'Content-Type: application/json' \
  --data-raw "{
    \"name\":\"MB-dev-gateway-$nodePrefix\",
    \"blockchain\":\"$blockchain\",
    \"zone\":\"AS\",
    \"network\":\"mainnet\"}" | jq -r '. | .id, .appKey' | sed -z -z 's/\n/,/g;s/,$/,AS\n/' >gatewaylist.csv

#-------------------------------------------
# check if node/gw are created in Portal successfully
#-------------------------------------------
GATEWAY_ID=$(cut -d ',' -f 1 gatewaylist.csv)
NODE_ID=$(cut -d ',' -f 1 nodelist.csv)

echo "        NODE/GW INFO        "
echo "----------------------------"
echo "Gateway ID: $GATEWAY_ID"
echo "Node ID: $NODE_ID"
echo "----------------------------"

# curl node info
gateway_reponse_code=$(curl -o /dev/null -s -w "%{http_code}\n" "https://portal.massbitroute.dev/mbr/gateway/$GATEWAY_ID" --header "Authorization: Bearer $bearer")
if [[ $gateway_reponse_code != 200 ]]; then
  echo "Create new gw in Portal: Failed"
  exit 1
fi
echo "Create new gw in Portal: Passed"

node_reponse_code=$(curl -o /dev/null -s -w "%{http_code}\n" "https://portal.massbitroute.dev/mbr/node/$NODE_ID" --header "Authorization: Bearer $bearer")
if [[ $node_reponse_code != 200 ]]; then
  echo "Create new node in Portal: Failed"
  exit 1
fi
echo "Create new node in Portal: Passed"


#-------------------------------------------
# create  node/gw tf files
#-------------------------------------------
sudo echo '
variable "project_prefix" {
  type        = string
  description = "The project prefix (mbr)."
}
variable "environment" {
  type        = string
  description = "Environment: dev, test..."
}
variable "default_zone" {
  type = string
}
variable "network_interface" {
  type = string
}
variable "email" {
  type = string
}
variable "map_machine_types" {
  type = map
}

' >test-nodes.tf

MASSBITROUTE_CORE_IP=$(cat MASSBITROUTE_CORE_IP)
MASSBITROUTE_PORTAL_IP=$(cat MASSBITROUTE_PORTAL_IP)
MASSBITROUTE_RUST_IP=$(cat MASSBITROUTE_RUST_IP)

while IFS="," read -r nodeId appId zone; do
  cat gateway-template-single | sed "s/\[\[GATEWAY_ID\]\]/$nodeId/g" | \
    sed "s/\[\[APP_KEY\]\]/$appId/g" | \
    sed "s/\[\[ZONE\]\]/$zone/g" | \
    sed "s/\[\[BLOCKCHAIN\]\]/$blockchain/g" | \
    sed "s/\[\[MASSBITROUTE_CORE_IP\]\]/$MASSBITROUTE_CORE_IP/g" | \
    sed "s/\[\[MASSBITROUTE_PORTAL_IP\]\]/$MASSBITROUTE_PORTAL_IP/g" | \
    sed "s/\[\[MASSBITROUTE_RUST_IP\]\]/$MASSBITROUTE_RUST_IP/g" | \
    sed "s/\[\[USER_ID\]\]/$USER_ID/g" >>test-nodes.tf
done < <(tail gatewaylist.csv)

while IFS="," read -r nodeId appId zone; do
  cat node-template-single | sed "s/\[\[GATEWAY_ID\]\]/$nodeId/g" | \
  sed "s/\[\[APP_KEY\]\]/$appId/g" | \
    sed "s/\[\[ZONE\]\]/$zone/g" | \
    sed "s/\[\[BLOCKCHAIN\]\]/$blockchain/g" | \
    sed "s/\[\[DATASOURCE\]\]/$dataSource/g" | \
    sed "s/\[\[MASSBITROUTE_CORE_IP\]\]/$MASSBITROUTE_CORE_IP/g" | \
    sed "s/\[\[MASSBITROUTE_PORTAL_IP\]\]/$MASSBITROUTE_PORTAL_IP/g" | \
    sed "s/\[\[MASSBITROUTE_RUST_IP\]\]/$MASSBITROUTE_RUST_IP/g" | \
    sed "s/\[\[USER_ID\]\]/$USER_ID/g" >>test-nodes.tf
done < <(tail nodelist.csv)


#-------------------------------------------
#  Spin up nodes VM on GCE
#-------------------------------------------
echo "Create node VMs on GCE: In Progress"
terraform init -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform init: Failed "
  exit 1
fi
sudo terraform plan -out=tfplan-node-gateway -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform plan: Failed "
  exit 1
fi
sudo terraform apply -input=false tfplan-node-gateway
if [[ "$?" != "0" ]]; then
  echo "terraform apply: Failed"
  exit 1
fi
echo "Create node VMs on GCE: Passed"

echo "Waiting for nodes to set up"
sleep 180

GW_IP=$(terraform output -raw mbr_gw_public_ip)

#-------------------------------------------
# Check if nodes are verified
#-------------------------------------------
while [[ "$gateway_status" != "verified" ]] && [[ "$node_status" != "verified" ]]; do
  echo "Checking node status: In Progress"

  # if [[ "$gateway_status" = "failed" ]] && [[ "$node_status" = "failed" ]]
  # then
  #   echo "---------------------------------"
  #   echo "Gateway status: $gateway_status"
  #   echo "Node status: $node_status"
  #   echo "---------------------------------"
  #   echo "Checking nodes verified status: Failed"
  #   exit 1
  # fi

  gateway_status=$(curl -s --location --request GET "https://portal.massbitroute.dev/mbr/gateway/$GATEWAY_ID" \
    --header "Authorization: Bearer $bearer" | jq -r ". | .status")

  node_status=$(curl -s --location --request GET "https://portal.massbitroute.dev/mbr/node/$NODE_ID" \
    --header "Authorization: Bearer $bearer" | jq -r ". | .status")

  echo "---------------------------------"
  echo "Gateway status: $gateway_status"
  echo "Node status: $node_status"
  echo "---------------------------------"
  sleep 10
done
echo "Checking node verified status: Passed"


#-------------------------------------------
# Test staking for NODES/GW
#-------------------------------------------
# register gateway
gateway_register_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/admin/register-provider' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"providerId\": \"$GATEWAY_ID\",
    \"operator\": \"$WALLET_ADDRESS\",
    \"providerType\": \"Gateway\",
    \"blockchain\": \"$blockchain\",
    \"network\": \"mainnet\"
}" | jq -r ". | .status")
if [[ "$gateway_register_response" != "success" ]]; then
  echo "Gateway registration: Failed "
  exit 1
fi
echo "Gateway registration: Passed"

# stake gateway
gateway_staking_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/staking-provider' \
  --header 'Content-Type: application/json' --data-raw "{
    \"memonic\": \"$MEMONIC\",
    \"providerId\": \"$GATEWAY_ID\",
    \"providerType\": \"Gateway\",
    \"blockchain\": \"$blockchain\",
    \"network\": \"mainnet\",
    \"amount\": \"100\"
}" | jq -r ". | .status")
if [[ "$gateway_staking_response" != "success" ]]; then
  echo "Gateway staking status: Failed "
  exit 1
fi
echo "Gateway staking status: Passed"

# register Node
node_register_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/admin/register-provider' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"providerId\": \"$NODE_ID\",
    \"operator\": \"$WALLET_ADDRESS\",
    \"providerType\": \"Node\",
    \"blockchain\": \"$blockchain\",
    \"network\": \"mainnet\"
}" | jq -r ". | .status")
if [[ "$node_register_response" != "success" ]]; then
  echo "Node registration: Failed "
  exit 1
fi
echo "Node registration: Passed"

node_staking_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/staking-provider' \
  --header 'Content-Type: application/json' --data-raw "{
    \"memonic\": \"$MEMONIC\",
    \"providerId\": \"$NODE_ID\",
    \"providerType\": \"Node\",
    \"blockchain\": \"$blockchain\",
    \"network\": \"mainnet\",
    \"amount\": \"100\"
}" | jq -r ". | .status")
if [[ "$node_staking_response" != "success" ]]; then
  echo "Node staking: Failed"
  exit 1
fi
echo "Node staking: Passed"

#-------------------------------------------
# Check staking status
#-------------------------------------------
# Check GW Staking status
gateway_staking_status=$(curl -s --location --request GET "https://portal.massbitroute.dev/mbr/gateway/$GATEWAY_ID" \
  --header "Authorization: Bearer $bearer" | jq -r ". | .status")

if [[ "$gateway_staking_status" != "staked" ]]; then
  echo "Verify Gateway staking status: Failed "
  exit 1
fi
echo "Verify Gateway staking status: Passed"

# Check node Staking status
node_staking_status=$(curl -s --location --request GET "https://portal.massbitroute.dev/mbr/node/$NODE_ID" \
  --header "Authorization: Bearer $bearer" | jq -r ". | .status")

if [[ "$node_staking_status" != "staked" ]]; then
  echo "Verify Node staking status: Failed"
  exit 1
fi
echo "Verify Node staking status: Passed"

#-------------------------------------------
# Test staking for PROJECT
#-------------------------------------------
project_staking_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/staking-project' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"memonic\": \"$MEMONIC\",
    \"projectId\": \"$PROJECT_ID\",
    \"blockchain\": \"$blockchain\",
    \"network\": \"mainnet\",
    \"amount\": \"100\"
}")
staking_message=$(echo $project_staking_response | jq -r ". | .message ")

if [[ "$staking_message" != "AlreadyExist (dapi): The provider/project is already registered." ]]
then
  staking_status=$(echo $project_staking_response | jq -r ". | .status ")
  if [[ "$project_staking_response" -eq 'staked' ]]; then
    echo "Verify Project staking status: Failed"
    exit 1
  fi
fi

echo "Verify Project staking status: Passed"

#-------------------------------------------
# Create dAPI
#-------------------------------------------
create_dapi_response=$(curl -s --location --request POST 'https://portal.massbitroute.dev/mbr/d-apis' \
  --header "Authorization: Bearer $bearer" \
  --header 'Content-Type: application/json' \
  --data-raw "{
    \"name\": \"test-dapi\",
    \"projectId\": \"$PROJECT_ID\"
}")
create_dapi_status=$(echo $create_dapi_response | jq -r '. | .status')
if [[ "$create_dapi_status" != "1" ]]; then
  echo "Create new dAPI: Failed"
  exit 1
fi
echo "Create new dAPI: Passed"


#-------------------------------------------
# Test call dAPI
#-------------------------------------------
apiId=$(echo $create_dapi_response | jq -r '. | .entrypoints[0].apiId')
appKey=$(echo $create_dapi_response | jq -r '. | .appKey')
dapiURL="https://$apiId.$blockchain-mainnet.massbitroute.dev/$appKey"
gateway_hosts_entry="$apiId.$blockchain-mainnet.massbitroute.dev"

# update host file for dAPI entry
echo "$GW_IP $gateway_hosts_entry" >> /etc/hosts
cat /etc/hosts

echo $dapiURL > DAPI_URL

if [ "$blockchain" = "eth" ]
then
  http_data='{
      "jsonrpc": "2.0",
      "method": "eth_getBlockByNumber",
      "params": [
          "latest",
          true
      ],
      "id": 1
  }'
elif [ "$blockchain" = "dot" ]
then
  http_data='{
    "jsonrpc": "2.0",
    "method": "chain_getBlock",
    "params": [],
    "id": 1
}'
fi

echo "Waiting for dAPI to configure"
sleep 60

dapi_response_code=$(curl -o /dev/null -s -w "%{http_code}\n" --location --request POST "$dapiURL" \
  --header 'Content-Type: application/json' \
  --data-raw "$http_data")
if [[ "$dapi_response_code" != "200" ]]; then
  echo "Calling dAPI: Failed"
  exit 1
fi
echo "Calling dAPI: Pass"


#-------------------------------------------
# Cleaning up test VMs
#-------------------------------------------
echo "Cleaning up VMs: In Progress"
terraform destroy -auto-approve
if [[ "$?" != "0" ]]; then
  echo "Failed to execute: terraform destroy "
  exit 1
fi
echo "Cleaning up VMs: Passed"

exit 0