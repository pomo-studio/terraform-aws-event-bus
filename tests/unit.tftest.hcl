mock_provider "aws" {
  alias = "primary"

  mock_resource "aws_cloudwatch_event_bus" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:event-bus/test-bus"
    }
  }

  mock_resource "aws_schemas_registry" {
    defaults = {
      arn = "arn:aws:schemas:us-east-1:123456789012:registry/test-bus"
    }
  }

  mock_resource "aws_cloudwatch_event_archive" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:archive/test-bus-archive"
    }
  }

  mock_resource "aws_cloudwatch_event_bus_policy" {
    defaults = {}
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-bus-cross-region-router"
      id  = "test-bus-cross-region-router"
    }
  }

  mock_resource "aws_iam_role_policy" {
    defaults = {}
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/test-bus/test-bus-replicate-to-dr"
    }
  }

  mock_resource "aws_cloudwatch_event_target" {
    defaults = {}
  }
}

mock_provider "aws" {
  alias = "dr"

  mock_resource "aws_cloudwatch_event_bus" {
    defaults = {
      arn = "arn:aws:events:us-west-2:123456789012:event-bus/test-bus"
    }
  }

  mock_resource "aws_cloudwatch_event_archive" {
    defaults = {
      arn = "arn:aws:events:us-west-2:123456789012:archive/test-bus-archive"
    }
  }

  mock_resource "aws_cloudwatch_event_bus_policy" {
    defaults = {}
  }
}

# -----------------------------------------------------------------------------
# Basic: defaults only
# -----------------------------------------------------------------------------

run "basic_defaults" {
  command = plan

  variables {
    name = "test-bus"
  }

  assert {
    condition     = aws_cloudwatch_event_bus.primary.name == "test-bus"
    error_message = "Primary bus name should match var.name"
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus.dr) == 1
    error_message = "DR bus should be created by default"
  }

  assert {
    condition     = length(aws_schemas_registry.primary) == 1
    error_message = "Schema registry should be created by default"
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.primary) == 1
    error_message = "Primary archive should be created by default"
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.dr) == 1
    error_message = "DR archive should be created by default"
  }

  assert {
    condition     = length(aws_iam_role.cross_region) == 0
    error_message = "Cross-region role should not be created by default"
  }
}

# -----------------------------------------------------------------------------
# DR disabled
# -----------------------------------------------------------------------------

run "dr_disabled" {
  command = plan

  variables {
    name      = "test-bus"
    enable_dr = false
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus.dr) == 0
    error_message = "DR bus should not be created when enable_dr = false"
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.dr) == 0
    error_message = "DR archive should not be created when enable_dr = false"
  }

  assert {
    condition     = output.bus_arn_dr == null
    error_message = "bus_arn_dr output should be null when enable_dr = false"
  }
}

# -----------------------------------------------------------------------------
# Schema registry disabled
# -----------------------------------------------------------------------------

run "schema_registry_disabled" {
  command = plan

  variables {
    name                   = "test-bus"
    enable_schema_registry = false
  }

  assert {
    condition     = length(aws_schemas_registry.primary) == 0
    error_message = "Schema registry should not be created when disabled"
  }

  assert {
    condition     = output.schema_registry_name == null
    error_message = "schema_registry_name output should be null when disabled"
  }
}

# -----------------------------------------------------------------------------
# Archive disabled
# -----------------------------------------------------------------------------

run "archive_disabled" {
  command = plan

  variables {
    name           = "test-bus"
    enable_archive = false
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.primary) == 0
    error_message = "Primary archive should not be created when disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.dr) == 0
    error_message = "DR archive should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Archive retention days
# -----------------------------------------------------------------------------

run "archive_retention" {
  command = plan

  variables {
    name                   = "test-bus"
    archive_retention_days = 90
  }

  assert {
    condition     = aws_cloudwatch_event_archive.primary[0].retention_days == 90
    error_message = "Primary archive retention should match var.archive_retention_days"
  }

  assert {
    condition     = aws_cloudwatch_event_archive.dr[0].retention_days == 90
    error_message = "DR archive retention should match var.archive_retention_days"
  }
}

# -----------------------------------------------------------------------------
# Cross-region routing enabled
# -----------------------------------------------------------------------------

run "cross_region_routing" {
  command = plan

  variables {
    name                        = "test-bus"
    enable_cross_region_routing = true
  }

  assert {
    condition     = length(aws_iam_role.cross_region) == 1
    error_message = "Cross-region IAM role should be created when routing is enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.cross_region) == 1
    error_message = "Cross-region routing rule should be created"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.cross_region) == 1
    error_message = "Cross-region routing target should be created"
  }
}

# -----------------------------------------------------------------------------
# Cross-region routing requires enable_dr
# -----------------------------------------------------------------------------

run "cross_region_requires_dr" {
  command = plan

  expect_failures = [var.enable_cross_region_routing]

  variables {
    name                        = "test-bus"
    enable_dr                   = false
    enable_cross_region_routing = true
  }
}

# -----------------------------------------------------------------------------
# Bus resource policy for cross-account publishers
# -----------------------------------------------------------------------------

run "cross_account_publishers" {
  command = plan

  variables {
    name = "test-bus"
    allowed_publisher_arns = [
      "arn:aws:iam::999999999999:root"
    ]
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus_policy.primary) == 1
    error_message = "Primary bus policy should be created when publishers are specified"
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus_policy.dr) == 1
    error_message = "DR bus policy should be created when publishers are specified and DR is enabled"
  }
}

# -----------------------------------------------------------------------------
# Name validation
# -----------------------------------------------------------------------------

run "invalid_bus_name" {
  command = plan

  expect_failures = [var.name]

  variables {
    name = "invalid name with spaces"
  }
}

# -----------------------------------------------------------------------------
# Resource naming
# -----------------------------------------------------------------------------

run "resource_naming" {
  command = plan

  variables {
    name = "payments-bus"
  }

  assert {
    condition     = aws_cloudwatch_event_archive.primary[0].name == "payments-bus-archive"
    error_message = "Archive name should be <name>-archive"
  }

  assert {
    condition     = aws_schemas_registry.primary[0].name == "payments-bus"
    error_message = "Schema registry name should match bus name"
  }
}
