#!/bin/bash


# revert old IP
rm massbitroute.dev 
cp massbitroute.dev.bak massbitroute.dev

git add .
git commit -m "Update entry for dapi [OLD] $OLD_API_IP  - [NEW] $NEW_API_IP"
# git push origin master