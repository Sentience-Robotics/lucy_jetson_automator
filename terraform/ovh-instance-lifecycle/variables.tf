variable "server_id" {
  description = "Existing Nova server UUID to start/stop."
  type        = string

  validation {
    condition     = length(trimspace(var.server_id)) > 0
    error_message = "server_id must be non-empty."
  }
}

variable "cloud_name" {
  description = "Entry name in clouds.yaml (OS_CLOUD)."
  type        = string
  default     = "openstack"
}

variable "desired_power" {
  description = "Target power state using Nova stop/start."
  type        = string

  validation {
    condition     = contains(["running", "stopped"], var.desired_power)
    error_message = "desired_power must be running or stopped."
  }
}
