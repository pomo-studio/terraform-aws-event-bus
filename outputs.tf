output "bus_name_primary" {
  description = "EventBridge bus name — primary region"
  value       = aws_cloudwatch_event_bus.primary.name
}

output "bus_arn_primary" {
  description = "EventBridge bus ARN — primary region"
  value       = aws_cloudwatch_event_bus.primary.arn
}

output "bus_name_dr" {
  description = "EventBridge bus name — DR region. Null if enable_dr = false."
  value       = var.enable_dr ? aws_cloudwatch_event_bus.dr[0].name : null
}

output "bus_arn_dr" {
  description = "EventBridge bus ARN — DR region. Null if enable_dr = false."
  value       = var.enable_dr ? aws_cloudwatch_event_bus.dr[0].arn : null
}

output "schema_registry_name" {
  description = "EventBridge Schema Registry name. Null if enable_schema_registry = false."
  value       = var.enable_schema_registry ? aws_schemas_registry.primary[0].name : null
}

output "archive_name_primary" {
  description = "EventBridge archive name — primary region. Null if enable_archive = false."
  value       = var.enable_archive ? aws_cloudwatch_event_archive.primary[0].name : null
}

output "archive_name_dr" {
  description = "EventBridge archive name — DR region. Null if enable_archive = false or enable_dr = false."
  value       = var.enable_dr && var.enable_archive ? aws_cloudwatch_event_archive.dr[0].name : null
}

output "cross_region_rule_arn" {
  description = "ARN of the cross-region routing rule. Null if enable_cross_region_routing = false."
  value       = var.enable_cross_region_routing ? aws_cloudwatch_event_rule.cross_region[0].arn : null
}
