#!/bin/bash
############# SENSITIVE DATA

if [ -z "$1" ]
  then
    echo "ERROR: Git branch name is required"
    exit 1
fi
DEPLOY_BRANCH=$1




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

nodeId="$(cat ../node-prefix)"

## CORE NODE
cat massbitroute-core-template-single | \
     sed "s/\[\[NODE_ID\]\]/$nodeId/g" | \
    sed "s/\[\[BRANCH_NAME\]\]/$GIT_BRANCH/g" | \
    sed "s/\[\[MERGE_BRANCH\]\]/$GIT_MERGE_BRANCH/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_USERNAME\]\]/$PRIVATE_GIT_READ_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_PASSWORD\]\]/$PRIVATE_GIT_READ_PASSWORD/g" | \
    sed "s/\[\[PRIVATE_GIT_DOMAIN\]\]/$PRIVATE_GIT_DOMAIN/g"  | \
    sed "s/\[\[PRIVATE_GIT_SSH_USERNAME\]\]/$PRIVATE_GIT_SSH_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_SSH_PASSWORD\]\]/$PRIVATE_GIT_SSH_PASSWORD/g" | \
    sed "s|\[\[DEPLOY_BRANCH\]\]|$DEPLOY_BRANCH|g" | \
    sed "s/\[\[GIT_API_TOKEN\]\]/$GIT_API_TOKEN/g"  >> test-nodes.tf

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

CORE_IP=$(terraform output -raw mbr_core_public_ip)
echo $CORE_IP > MASSBITROUTE_CORE_IP
