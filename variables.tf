variable "name" {
  description = "Bus name — used as-is for the EventBridge bus and as prefix for all related resources"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+$", var.name))
    error_message = "Bus name must contain only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "enable_dr" {
  description = "Deploy a matching bus in the DR region (aws.dr provider). Disable for dev/staging to reduce cost. Non-production when false."
  type        = bool
  default     = true
}

variable "enable_schema_registry" {
  description = "Create an EventBridge Schema Registry in the primary region for event contract documentation. Requires EventBridge Schemas to be available in the primary region."
  type        = bool
  default     = true
}

variable "enable_archive" {
  description = "Enable event archiving on both buses for replay capability"
  type        = bool
  default     = true
}

variable "archive_retention_days" {
  description = "Days to retain archived events. 0 = indefinite retention."
  type        = number
  default     = 0
}

variable "enable_cross_region_routing" {
  description = "Automatically route all primary bus events to the DR bus. Requires enable_dr = true."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_cross_region_routing || var.enable_dr
    error_message = "enable_cross_region_routing requires enable_dr = true."
  }
}

variable "allowed_publisher_arns" {
  description = "IAM principal ARNs allowed to publish to this bus via resource policy. Leave empty when all publishers are in the same account."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
