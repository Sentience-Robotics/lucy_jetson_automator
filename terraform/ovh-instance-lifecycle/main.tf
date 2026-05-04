# Lifecycle-only automation for an existing OpenStack instance (OVH Public Cloud).
# Does not manage VM creation/deletion. Requires OS_CLIENT_CONFIG_FILE (clouds.yaml) in the environment.

resource "terraform_data" "nova_power" {
  lifecycle {
    prevent_destroy = true
  }

  triggers_replace = [
    var.desired_power,
    var.server_id,
    var.cloud_name,
  ]

  provisioner "local-exec" {
    environment = {
      OS_CLOUD = var.cloud_name
    }
    command = <<-EOT
      set -euo pipefail
      case "${var.desired_power}" in
        stopped)
          openstack server stop "${var.server_id}"
          ;;
        running)
          openstack server start "${var.server_id}"
          ;;
        *)
          echo "invalid desired_power"
          exit 1
          ;;
      esac
    EOT
  }
}
