# =============================================================================
# Event Bus — Shared EventBridge Infrastructure
# Primary + DR bus with optional schema registry, archive, and cross-region routing
# =============================================================================

# -----------------------------------------------------------------------------
# Event Buses
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus" "primary" {
  provider = aws.primary
  name     = var.name
  tags     = var.tags
}

resource "aws_cloudwatch_event_bus" "dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  name     = var.name
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Schema Registry — primary region only (single source of truth)
# -----------------------------------------------------------------------------

resource "aws_schemas_registry" "primary" {
  count       = var.enable_schema_registry ? 1 : 0
  provider    = aws.primary
  name        = var.name
  description = "Event schema registry for the ${var.name} bus"
  tags        = var.tags
}

# -----------------------------------------------------------------------------
# Archive — preserves all events for replay
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_archive" "primary" {
  count            = var.enable_archive ? 1 : 0
  provider         = aws.primary
  name             = "${var.name}-archive"
  event_source_arn = aws_cloudwatch_event_bus.primary.arn
  retention_days   = var.archive_retention_days
}

resource "aws_cloudwatch_event_archive" "dr" {
  count            = var.enable_dr && var.enable_archive ? 1 : 0
  provider         = aws.dr
  name             = "${var.name}-archive"
  event_source_arn = aws_cloudwatch_event_bus.dr[0].arn
  retention_days   = var.archive_retention_days
}

# -----------------------------------------------------------------------------
# Bus Resource Policy — cross-account publishers
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus_policy" "primary" {
  count          = length(var.allowed_publisher_arns) > 0 ? 1 : 0
  provider       = aws.primary
  event_bus_name = aws_cloudwatch_event_bus.primary.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPublishers"
      Effect = "Allow"
      Principal = {
        AWS = var.allowed_publisher_arns
      }
      Action   = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.primary.arn
    }]
  })
}

resource "aws_cloudwatch_event_bus_policy" "dr" {
  count          = var.enable_dr && length(var.allowed_publisher_arns) > 0 ? 1 : 0
  provider       = aws.dr
  event_bus_name = aws_cloudwatch_event_bus.dr[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPublishers"
      Effect = "Allow"
      Principal = {
        AWS = var.allowed_publisher_arns
      }
      Action   = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.dr[0].arn
    }]
  })
}

# -----------------------------------------------------------------------------
# Cross-Region Routing — replicates all primary events to DR bus
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cross_region" {
  count    = var.enable_cross_region_routing ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-cross-region-router"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cross_region" {
  count    = var.enable_cross_region_routing ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-cross-region-router"
  role     = aws_iam_role.cross_region[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.dr[0].arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "cross_region" {
  count          = var.enable_cross_region_routing ? 1 : 0
  provider       = aws.primary
  name           = "${var.name}-replicate-to-dr"
  description    = "Replicates all events from the ${var.name} bus to the DR region"
  event_bus_name = aws_cloudwatch_event_bus.primary.name
  event_pattern  = jsonencode({})
  tags           = var.tags
}

resource "aws_cloudwatch_event_target" "cross_region" {
  count          = var.enable_cross_region_routing ? 1 : 0
  provider       = aws.primary
  rule           = aws_cloudwatch_event_rule.cross_region[0].name
  event_bus_name = aws_cloudwatch_event_bus.primary.name
  target_id      = "dr-bus"
  arn            = aws_cloudwatch_event_bus.dr[0].arn
  role_arn       = aws_iam_role.cross_region[0].arn
}
