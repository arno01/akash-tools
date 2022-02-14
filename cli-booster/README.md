# Akash cli-booster

A little wrapper that's supposed to make Akash CLI experience better.

Written quickly over the weekend, so it can look ugly to the linter.

Feel free to contribute via pull request!

## Pre-requisites

- this has been tested only in Linux (Ubuntu). It might not work in macOS/Windows(cygwin), if you fix the issues, please file a PR;
- make sure you have these programs installed: `bash, grep, column, awk, jq, bc, nc, curl, akash`;
- make sure to have an akash account address (run `akash keys add default` to create one) with non-empty balance (5 AKT deposit is required for each deployment);

## Features

- automatically detects keyring backend;
- switching between mainnet/edgenet/testnet;
- switching between orders / deployments;
- aborts when Akash RPC is 30sec behind the or ahead of time;
- shows detailed TX error for every `akash tx` command;
- shows provider `host_uri` and is checking their liveness;

## Usage

1. Initialize
```
. akash.source
```

> If you are using your key for the first time, make sure to create the client cert:
> 
> ```
> akash_mkcert
> ```

2. Deploy Akash manifest
```
akash_deploy deploy.yaml
```

3. Accept the bid
```
akash_accept
```

4. Send manifest file to the provider
```
akash_send_manifest deploy.yaml
```

That's all!

## What's next?

- Drop into your deployment's shell
```
akash_shell sh
```

- Check your deployment status
```
akash_status
```

- Close deployment
```
akash_close
```

- Find your deployment
```
akash_deployments
```

- Find your order
> List orders you have not accepted the bid for. (i.e. have not ran lease create yet).
>  Hint: You can close them to release the deposit.
```
akash_orders
```

- Update your deployment
```
akash_update deploy.yaml
akash_send_manifest deploy.yaml
```

- Watch the logs
```
akash_logs -f
```

- More commands to try
```
akash_provider
akash_providers
akash_leases
akash_leases_all
akash_balances
set_net
set_rpc
check_rpc
detect_keyring_backend
auto_select_key
```

## Switching between the networks edgenet/testnet

> simply `export NET=<mainnet/edgenet/testnet>`

Example:

```
export NET=testnet
. akash.source
```

or if `akash.source` already sourced:

```
export NET=testnet
set_net
```

## Logging

To enable debugging level:

> 1 ERROR, 2 INFO (default), 3 DEBUG

```
export LOGLEVEL=3
```

## Disable provider port check

Not recommended, but can accelerate `akash_accept` when displaying the bids:

```
export NO_PROVIDER_PORT_CHECK=1
```

## FAQ

- Q: Command froze
- A: Ctrl+C and re-try
