output "environment_name" {
  description = "The environment name passed in for this run"
  value       = var.environment_name
}

output "noop_id" {
  description = "Stable ID of the no-op null resource (confirms apply ran)"
  value       = null_resource.noop.id
}
