#!/bin/bash

./deploy-mb-core.sh dev
./build-hosts-file.sh
./single-node-test.sh eth