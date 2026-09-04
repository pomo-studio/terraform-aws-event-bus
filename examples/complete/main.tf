terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

# Shared event bus for a microservices platform.
# All services publish to this bus and deploy their own event-consumer module
# instances pointing at bus_name_primary / bus_name_dr.

module "bus" {
  source  = "pomo-studio/event-bus/aws"
  version = "~> 1.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  name = "platform-bus"

  # Archive all events indefinitely — replay any incident
  enable_archive         = true
  archive_retention_days = 0

  # Cross-region replication — all events flow to DR bus automatically
  enable_cross_region_routing = true

  # Allow a separate account's services to publish
  allowed_publisher_arns = [
    "arn:aws:iam::999999999999:root"
  ]

  tags = {
    Environment = "production"
    Platform    = "payments"
  }
}
