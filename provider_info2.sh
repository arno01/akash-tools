#!/bin/bash
# Filename: provider_info2.sh
#
# Version: 0.2 - 30-April-2024 (provider >=v0.5.x)
#
# TODO: leverage Feature Discovery grpcurl -insecure <provider-url>:8444 akash.provider.v1.ProviderRPC.GetStatus

# Check if the provider argument is supplied
if [ -z "$1" ]; then
    echo "Usage: $0 <provider-hostname>"
    echo "Example: provider_info.sh provider.hurricane.akash.pub"
    exit 1
fi

# Define the provider from the first script argument
PROVIDER=$1

if [[ $PROVIDER == akash1* ]]; then
  if ! type -P provider-services > /dev/null; then
    echo "For the provider detection by its akash1 address, please install provider-services from https://github.com/akash-network/provider/releases"
    exit 1
  fi

  # https://github.com/akash-network/net/blob/main/mainnet/rpc-nodes.txt
  export AKASH_NODE=https://rpc.akashnet.net:443

  PROVIDER="$(provider-services query provider get $PROVIDER -o json | jq -r '.host_uri')"
fi

# strip http(s):// and trailing stuff if present, and detect the port
#if [[ $PROVIDER =~ ^https?://([^:]+)(:8443)?(.*)?$ ]]; then
if [[ $PROVIDER =~ (^https?://)?([^:/]+):?([0-9]+)?(.*)?$ ]]; then
    # Capture the URL without the protocol and port
    domain_part=${BASH_REMATCH[2]}
    port_part=${BASH_REMATCH[3]:-8443}
    path_part=${BASH_REMATCH[4]}

    # Construct the final string
    s="$domain_part:$port_part"
else
    s=$PROVIDER
fi
PROVIDER=$s

# Execute the updated curl and jq command
JSON="$(curl -sk https://${PROVIDER}/status)"

echo "PROVIDER INFO"
provider_address=$(echo "$JSON" | jq -r '.address')
echo "BALANCE: $(provider-services query bank balances $provider_address -o json | jq -r '.balances[] | select(.denom == "uakt") | .amount // 0|tonumber/pow(10;6)')"
echo "$JSON" | jq -r '["hostname","address"],[.cluster_public_hostname, .address] | @csv' | column -t -s,

echo
echo "Total/Available/Used (t/a/u) per node:"
echo "$JSON" | jq -r '
  ["name", "cpu(t/a/u)", "gpu(t/a/u)", "mem(t/a/u GiB)", "ephemeral(t/a/u GiB)"],
  (.cluster.inventory.available.nodes?[] // empty |
    [
      .name,
      ((.allocatable.cpu / 1000)|tostring) + "/" + ((.available.cpu / 1000)|tostring) + "/" + (((.allocatable.cpu - .available.cpu) / 1000)|tostring),
      (.allocatable.gpu|tostring) + "/" + (.available.gpu|tostring) + "/" + ((.allocatable.gpu - .available.gpu)|tostring),
      ((.allocatable.memory / pow(1024;3) * 100 | round / 100)|tostring) + "/" + ((.available.memory / pow(1024;3) * 100 | round / 100)|tostring) + "/" + (((.allocatable.memory - .available.memory) / pow(1024;3) * 100 | round / 100)|tostring) + "",
      ((.allocatable.storage_ephemeral / pow(1024;3) * 100 | round / 100)|tostring) + "/" + ((.available.storage_ephemeral / pow(1024;3) * 100 | round / 100)|tostring) + "/" + (((.allocatable.storage_ephemeral - .available.storage_ephemeral) / pow(1024;3) * 100 | round / 100)|tostring)
    ]
  ) |
  @csv
' | column -t -s,

echo
echo "ACTIVE TOTAL:"
echo "$JSON" | jq -r '
  ["cpu(cores)", "gpu", "mem(GiB)", "ephemeral(GiB)", "beta1(GiB)", "beta2(GiB)", "beta3(GiB)"],
  ( .cluster.inventory.active? // empty |
    [
      ([.[].cpu] | add / 1000),
      ([.[].gpu] | add),
      (([.[].memory] | add / pow(1024;3)) * 100 | round / 100),
      (([.[].storage_ephemeral] | add / pow(1024;3)) * 100 | round / 100),
      ([.[].storage // empty | to_entries[] |select(.[]|tostring | test("beta1")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100),
      ([.[].storage // empty | to_entries[] |select(.[]|tostring | test("beta2")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100),
      ([.[].storage // empty | to_entries[] |select(.[]|tostring | test("beta3")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100)
    ] ) | @csv' | column -t -s,

echo
echo "PERSISTENT STORAGE:"
echo "$JSON" | jq -r '["storage class","available space(GiB)"], (.cluster.inventory.available.storage? // empty | .[] | [(.class),(.size/pow(1024;3) * 100 | round / 100)]) | @csv' | column -t -s,

echo
echo "PENDING TOTAL:"
echo "$JSON" | jq -r '
  ["cpu(cores)", "gpu", "mem(GiB)", "ephemeral(GiB)", "beta1(GiB)", "beta2(GiB)", "beta3(GiB)"],
  ( .cluster.inventory.pending? // empty |
    [
      ([.[].cpu] | add / 1000),
      ([.[].gpu] | add),
      (([.[].memory] | add / pow(1024;3)) * 100 | round / 100),
      (([.[].storage_ephemeral] | add / pow(1024;3)) * 100 | round / 100),
      ([.[].storage? // empty | to_entries[] |select(.[]|tostring | test("beta1")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100),
      ([.[].storage? // empty | to_entries[] |select(.[]|tostring | test("beta2")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100),
      ([.[].storage? // empty | to_entries[] |select(.[]|tostring | test("beta3")) | .value] | (add // 0) / pow(1024;3) * 100 | round / 100)
    ] ) | @csv' | column -t -s,
