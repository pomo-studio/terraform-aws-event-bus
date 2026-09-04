# terraform-aws-event-bus

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-event-bus/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-event-bus/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/event-bus/aws)

Terraform module for shared AWS EventBridge bus infrastructure — the foundation layer for event-driven microservices architectures.

- Multi-region bus deployed to primary + DR simultaneously — same name in both regions, single module call
- EventBridge Schema Registry for event contract documentation — prevents breaking changes between services
- Event archive with configurable retention — replay any past event for debugging or incident recovery
- Cross-region event routing — primary bus events automatically replicated to the DR bus
- Bus resource policy for cross-account publishers — multi-account microservices out of the box

**Registry**: `pomo-studio/event-bus/aws`

## Usage

### Basic

```hcl
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "bus" {
  source  = "pomo-studio/event-bus/aws"
  version = "~> 1.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  name = "payments-bus"
}
```

Pass `module.bus.bus_name_primary` and `module.bus.bus_name_dr` to your `event-consumer` module instances.

### Complete: cross-region replication + cross-account publishers

```hcl
module "bus" {
  source  = "pomo-studio/event-bus/aws"
  version = "~> 1.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  name = "platform-bus"

  enable_archive              = true
  archive_retention_days      = 0     # indefinite
  enable_cross_region_routing = true  # all events flow to DR automatically

  allowed_publisher_arns = [
    "arn:aws:iam::999999999999:root"  # external account
  ]

  tags = { Environment = "production" }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | required | Bus name — used as-is for the EventBridge bus and as prefix for all related resources |
| `enable_dr` | `bool` | `true` | Deploy a matching bus in the DR region. Disable for dev/staging. |
| `enable_schema_registry` | `bool` | `true` | Create an EventBridge Schema Registry in the primary region |
| `enable_archive` | `bool` | `true` | Enable event archiving on both buses |
| `archive_retention_days` | `number` | `0` | Days to retain archived events. `0` = indefinite. |
| `enable_cross_region_routing` | `bool` | `false` | Route all primary bus events to the DR bus. Requires `enable_dr = true`. |
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principal ARNs for cross-account bus resource policy. Empty = same-account only. |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `bus_name_primary` | EventBridge bus name — primary region |
| `bus_arn_primary` | EventBridge bus ARN — primary region |
| `bus_name_dr` | EventBridge bus name — DR region. Null if `enable_dr = false`. |
| `bus_arn_dr` | EventBridge bus ARN — DR region. Null if `enable_dr = false`. |
| `schema_registry_name` | Schema Registry name. Null if `enable_schema_registry = false`. |
| `archive_name_primary` | Archive name — primary region. Null if `enable_archive = false`. |
| `archive_name_dr` | Archive name — DR region. Null if `enable_archive = false` or `enable_dr = false`. |
| `cross_region_rule_arn` | Cross-region routing rule ARN. Null if `enable_cross_region_routing = false`. |

## What it creates

Per module call:
- 2× `aws_cloudwatch_event_bus` (primary + DR)

Conditional:
- `aws_schemas_registry` in primary region (`enable_schema_registry = true`)
- 2× `aws_cloudwatch_event_archive` (`enable_archive = true`)
- 2× `aws_cloudwatch_event_bus_policy` (`allowed_publisher_arns` non-empty)
- `aws_iam_role` + `aws_iam_role_policy` + `aws_cloudwatch_event_rule` + `aws_cloudwatch_event_target` (`enable_cross_region_routing = true`)

## Design decisions

**Bus as shared infrastructure** — in microservices, the bus belongs to no single service. This module creates the bus as a standalone resource; individual services deploy their own consumer stacks (queues, Lambdas, alarms) pointing at the bus outputs. Pairs with `pomo-studio/event-pipeline/aws` for the consumer side.

**Schema Registry in primary only** — event contracts are a single source of truth. DR-region schema registries would require a synchronisation mechanism that adds complexity without benefit; the primary registry is the canonical reference.

**Cross-region routing is opt-in** — for most use cases, services deploy independent consumers in each region. Cross-region routing is provided for active-active patterns where every event must appear on both buses regardless of origin region.

**`enable_dr = false` is not production** — disabling DR removes the DR bus and all related resources. Acceptable for dev/staging cost reduction; document this when using in non-production environments.

**Bus resource policy is additive** — leaving `allowed_publisher_arns` empty creates no policy, which means only same-account principals can publish (AWS default). Add ARNs only when cross-account access is required.

## Examples

- [`examples/basic`](examples/basic/) — minimal bus, no cross-region routing
- [`examples/complete`](examples/complete/) — cross-region replication, cross-account publishers

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.5.0` |
| AWS provider | `>= 5.0, < 7.0` |

## License

MIT
