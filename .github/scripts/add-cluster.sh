 #!/bin/bash

# Usage:
# 
# export GITHUB_TOKEN=<your-token>
# export GITHUB_USER=<your-username>
#
# add-cluster.sh CLUSTER REGION

CLUSTER=$1
REGION=$2

mkdir -p  ./clusters/$CLUSTER/$REGION
cp ./scripts/templates/clusters ./clusters/$CLUSTER/$REGION
sed -i 's/{CLUSTER}/'$CLUSTER'/g' ./clusters/$CLUSTER/$REGION
sed -i 's/{REGION}/'$REGION'/g' ./clusters/$CLUSTER/$REGION

mkdir -p  ./tenants/$CLUSTER/$REGION

flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --path=clusters/$CLUSTER/$REGION
