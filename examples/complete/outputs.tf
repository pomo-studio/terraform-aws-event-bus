output "bus_name_primary" {
  description = "Pass to event-consumer modules in the primary region"
  value       = module.bus.bus_name_primary
}

output "bus_name_dr" {
  description = "Pass to event-consumer modules in the DR region"
  value       = module.bus.bus_name_dr
}

output "schema_registry_name" {
  description = "Register event schemas here for contract documentation"
  value       = module.bus.schema_registry_name
}
