# Event bus basic

Minimal shared event bus in two regions.

## What it creates

- EventBridge bus `my-app-bus` in the primary and DR regions.
- A schema registry and event archives, since both default to on.

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
