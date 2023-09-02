#!/bin/bash
# Filename: provider_info.sh
#
# Version: 0.1 - September 02 2023
#
# TODO: add ability to pass the provider akash1... address
#

# Check if the provider argument is supplied
if [ -z "$1" ]; then
    echo "Usage: $0 <provider-hostname>"
    echo "Example: provider_info.sh provider.hurricane.akash.pub"
    exit 1
fi

# Define the provider from the first script argument
PROVIDER=$1

# Execute the updated curl and jq command
curl -sk "https://${PROVIDER}:8443/status" | jq -r '
[
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
