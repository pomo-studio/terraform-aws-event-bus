# Event bus complete

Production-style shared bus with replay, cross-region routing, and cross-account publish.

## What it creates

- EventBridge bus `platform-bus` in the primary and DR regions.
- Archives on both buses with indefinite retention (0 days).
- A cross-region rule that forwards primary events to the DR bus.
- A bus policy that lets account `999999999999` publish.

## Before you start

- AWS credentials. Primary provider `us-east-1`, DR provider `us-west-2`.
- Uses the published registry module `pomo-studio/event-bus/aws`, version `~> 1.0`.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
