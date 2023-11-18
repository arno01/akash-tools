#!/bin/bash
# Filename: provider_info.sh
#
# Version: 0.2 - November 18 2023
#

# Check if the provider argument is supplied
if [ -z "$1" ]; then
    echo "Usage: $0 <provider-hostname>"
    echo "Example: provider_info.sh provider.hurricane.akash.pub"
    exit 1
fi

# Define the provider from the first script argument
PROVIDER=$1

if [[ $PROVIDER == akash1* ]]; then
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
curl -sk "https://${PROVIDER}/status" | jq -r '
[ [.cluster_public_hostname, .address],
  ["type", "cpu", "gpu", "ram", "ephemeral", "persistent"],
  (
    ["used"] +
    (
      .cluster.inventory.active // [] |
      [
        ( [.[].cpu // 0|tonumber] | add / 1000 ),
        ( [.[].gpu // 0|tonumber] | add ),
        ( [.[].memory // 0|tonumber] | add / pow(1024;3) ),
        ( [.[].storage_ephemeral // 0|tonumber] | add / pow(1024;3) ),
        ( [.[].storage?.beta1 // .[].storage?.beta2 // .[].storage?.beta3 // 0 | tonumber] | add / pow(1024;3) )
      ]
    )
  ),
  (
    ["pending"] +
    (
      .cluster.inventory.pending // [] |
      [
        ( [.[].cpu // 0|tonumber] | add / 1000 ),
        ( [.[].gpu // 0|tonumber] | add ),
        ( [.[].memory // 0|tonumber] | add / pow(1024;3) ),
        ( [.[].storage_ephemeral // 0|tonumber] | add / pow(1024;3) ),
        ( [.[].storage?.beta1 // .[].storage?.beta2 // .[].storage?.beta3 // 0 | tonumber] | add / pow(1024;3) )
      ]
    )
  ),
  (
    ["available"] +
    (
      [
        ([.cluster.inventory.available.nodes[]?.cpu // empty] | add / 1000),
        ([.cluster.inventory.available.nodes[]?.gpu // empty] | add ),
        ([.cluster.inventory.available.nodes[]?.memory // empty] | add / pow(1024;3)),
        ([.cluster.inventory.available.nodes[]?.storage_ephemeral // empty] | add / pow(1024;3)),
        ([.cluster.inventory.available.storage[]? | select(.class | test("beta[1-3]"))] | if length == 0 then 0 else ([.[].size] | add / pow(1024;3)) end)
      ]
    )
  ),
  (
    .cluster.inventory.available.nodes[] |
    (
      ["node", .cpu / 1000, .gpu, .memory / pow(1024;3), .storage_ephemeral / pow(1024;3), "N/A"]
    )
  )
] | .[] | @tsv' | column -t
