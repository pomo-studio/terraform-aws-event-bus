# terraform-aws-event-bus

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-event-bus/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-event-bus/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/event-bus/aws)

- [Changelog](CHANGELOG.md)

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws.dr"></a> [aws.dr](#provider\_aws.dr) | 6.63.0 |
| <a name="provider_aws.primary"></a> [aws.primary](#provider\_aws.primary) | 6.63.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_event_archive.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_archive) | resource |
| [aws_cloudwatch_event_archive.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_archive) | resource |
| [aws_cloudwatch_event_bus.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus) | resource |
| [aws_cloudwatch_event_bus.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus) | resource |
| [aws_cloudwatch_event_bus_policy.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy) | resource |
| [aws_cloudwatch_event_bus_policy.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy) | resource |
| [aws_cloudwatch_event_rule.cross_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.cross_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.cross_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cross_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_schemas_registry.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/schemas_registry) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_publisher_arns"></a> [allowed\_publisher\_arns](#input\_allowed\_publisher\_arns) | IAM principal ARNs allowed to publish to this bus via resource policy. Leave empty when all publishers are in the same account. | `list(string)` | `[]` | no |
| <a name="input_archive_retention_days"></a> [archive\_retention\_days](#input\_archive\_retention\_days) | Days to retain archived events. 0 = indefinite retention. | `number` | `0` | no |
| <a name="input_enable_archive"></a> [enable\_archive](#input\_enable\_archive) | Enable event archiving on both buses for replay capability | `bool` | `true` | no |
| <a name="input_enable_cross_region_routing"></a> [enable\_cross\_region\_routing](#input\_enable\_cross\_region\_routing) | Automatically route all primary bus events to the DR bus. Requires enable\_dr = true. | `bool` | `false` | no |
| <a name="input_enable_dr"></a> [enable\_dr](#input\_enable\_dr) | Deploy a matching bus in the DR region (aws.dr provider). Disable for dev/staging to reduce cost. Non-production when false. | `bool` | `true` | no |
| <a name="input_enable_schema_registry"></a> [enable\_schema\_registry](#input\_enable\_schema\_registry) | Create an EventBridge Schema Registry in the primary region for event contract documentation. Requires EventBridge Schemas to be available in the primary region. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Bus name — used as-is for the EventBridge bus and as prefix for all related resources | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_archive_name_dr"></a> [archive\_name\_dr](#output\_archive\_name\_dr) | EventBridge archive name — DR region. Null if enable\_archive = false or enable\_dr = false. |
| <a name="output_archive_name_primary"></a> [archive\_name\_primary](#output\_archive\_name\_primary) | EventBridge archive name — primary region. Null if enable\_archive = false. |
| <a name="output_bus_arn_dr"></a> [bus\_arn\_dr](#output\_bus\_arn\_dr) | EventBridge bus ARN — DR region. Null if enable\_dr = false. |
| <a name="output_bus_arn_primary"></a> [bus\_arn\_primary](#output\_bus\_arn\_primary) | EventBridge bus ARN — primary region |
| <a name="output_bus_name_dr"></a> [bus\_name\_dr](#output\_bus\_name\_dr) | EventBridge bus name — DR region. Null if enable\_dr = false. |
| <a name="output_bus_name_primary"></a> [bus\_name\_primary](#output\_bus\_name\_primary) | EventBridge bus name — primary region |
| <a name="output_cross_region_rule_arn"></a> [cross\_region\_rule\_arn](#output\_cross\_region\_rule\_arn) | ARN of the cross-region routing rule. Null if enable\_cross\_region\_routing = false. |
| <a name="output_schema_registry_name"></a> [schema\_registry\_name](#output\_schema\_registry\_name) | EventBridge Schema Registry name. Null if enable\_schema\_registry = false. |
<!-- END_TF_DOCS -->

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

## License

MIT
