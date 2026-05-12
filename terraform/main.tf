terraform {
  required_version = ">= 1.0.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ─────────────────────────────────────────────
# No-op resource — creates and destroys nothing
# in the real world. Safe for approval-flow testing.
# ─────────────────────────────────────────────
resource "null_resource" "noop" {
  triggers = {
    environment = var.environment_name
    timestamp   = var.timestamp
  }
}
