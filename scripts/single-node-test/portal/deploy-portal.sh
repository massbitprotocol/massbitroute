#!/bin/bash
############# SENSITIVE DATA

#-------------------------------------------
# create terraform file for new node
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
}' >test-nodes.tf

echo "Current working directory: $(pwd)"
nodeId="$(cat ../node-prefix)"
MASSBITROUTE_CORE_IP = "$(cat ../core-api/MASSBITROUTE_CORE_IP)"

## PORTAL NODE
cat massbitroute-portal-template-single | \
    sed "s/\[\[NODE_ID\]\]/$nodeId/g" | \
    sed "s/\[\[BRANCH_NAME\]\]/$GIT_BRANCH/g" | \
    sed "s/\[\[MERGE_BRANCH\]\]/$GIT_MERGE_BRANCH/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_USERNAME\]\]/$PRIVATE_GIT_READ_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_PASSWORD\]\]/$PRIVATE_GIT_READ_PASSWORD/g" | \
    sed "s/\[\[PRIVATE_GIT_DOMAIN\]\]/$PRIVATE_GIT_DOMAIN/g" | \
    sed "s/\[\[PRIVATE_GIT_SSL_USERNAME\]\]/$PRIVATE_GIT_SSL_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_SSL_PASSWORD\]\]/$PRIVATE_GIT_SSL_PASSWORD/g"  | \
    sed "s/\[\[PRIVATE_GIT_SSH_USERNAME\]\]/$PRIVATE_GIT_SSH_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_SSH_PASSWORD\]\]/$PRIVATE_GIT_SSH_PASSWORD/g" | \
    sed "s/\[\[GIT_API_TOKEN\]\]/$GIT_API_TOKEN/g" | \
    sed "s/\[\[MASSBITROUTE_CORE_IP\]\]/$MASSBITROUTE_CORE_IP/g" >> test-nodes.tf

cat test-nodes.tf

#-------------------------------------------
#  Spin up new VM on GCE
#-------------------------------------------
echo "Create new node VMs on GCE: In Progress"
terraform init -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform init: Failed "
  exit 1
fi
sudo terraform plan -out=tfplan -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform plan: Failed "
  exit 1
fi
sudo terraform apply -input=false tfplan
if [[ "$?" != "0" ]]; then
  echo "terraform apply: Failed"
  exit 1
fi
echo "Create node VMs on GCE: Passed"

PORTAL_IP=$(terraform output -raw mbr_portal_public_ip)
echo $PORTAL_IP > MASSBITROUTE_PORTAL_IP
