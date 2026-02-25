---
name: deploy-orb-core
description: Deploy orb-core to a device over SSH. Use when the user wants to build, deploy, or update orb-core on an Orb device.
---

# Deploy Orb Core

## Prerequisites

- Nix
- An Orb IP (alternatively, ORB_IP env var), or an orb id. You can use `orb-<orb_id>.local` as the address if you know it.
- WORLDCOIN_PW env var

## Step 1: Build orb-core

If Pearl:

```bash
nix/cross_pearl.sh nix/release.sh --no-default-features --features pearl,stage,tensorrt
```

If Diamond:

```bash
nix/cross_diamond.sh nix/release.sh
```

## Step 3: Deploy to device

Copy the built binary to the device with scp to the `/usr/local/bin/orb-core` path on the orb.
User is `worldcoin`, password is WORLDCOIN_PW, and ip address is ORB_IP.

`/usr/local/bin` is protected so you will need to either do something like:
```bash
ssh user@host "sudo tee /protected/path/file > /dev/null" < localfile
```

Or you will need to copy to `/home/worldcoin` in the orb, and then use sudo to copy to `/usr/local/bin`


## Step 4: Stop worldcoin-control-api and worldcoin-core

Check if the following systemd services are running in the orb via ssh, and if so stop them:
- `worldcoin-control-api`
- `worldcoin-core`

Then start `worldcoin-core` systemd service
