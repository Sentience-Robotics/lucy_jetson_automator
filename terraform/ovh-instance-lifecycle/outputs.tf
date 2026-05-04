output "server_id" {
  value       = var.server_id
  description = "Nova server UUID acted upon."
}

output "desired_power" {
  value       = var.desired_power
  description = "Requested power state."
}
