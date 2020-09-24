#!/usr/bin/env sh

set -e

resource_group=$1
echo "$resource_group"
cluster_name=$2
echo "$cluster_name"
vnet_name=$3

echo "Creating Azure Red Hat OpenShift cluster"
az aro create \
  --resource-group "$resource_group" \
  --name "$cluster_name" \
  --vnet "$vnet_name" \
  --vnet-resource-group "$resource_group" \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet

apiServer=$(az aro show -g "$resource_group" -n "$cluster_name" --query apiserverProfile.url -o tsv)
kubeUser=$(az aro list-credentials -g "$resource_group" -n "$cluster_name" | jq -r .kubeadminUsername)
kubePassword=$(az aro list-credentials -g "$resource_group" -n "$cluster_name" | jq -r .kubeadminPassword)
openshiftVersion=$(az aro show -g "$resource_group" -n "$cluster_name" --query clusterProfile.version -o tsv)

echo "Installing Openshift CLI version $openshiftVersion"
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$openshiftVersion/openshift-client-linux.tar.gz" -o oc.tar.gz && \
  tar -zxvf oc.tar.gz

echo "Logging in"
./oc login "$apiServer" -u "$kubeUser" -p "$kubePassword"
echo "Creating the 'consul' project"
./oc new-project consul