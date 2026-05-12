variable "environment_name" {
  description = "Name of the environment being tested (used only as a trigger label)"
  type        = string
  default     = "test-env"
}

variable "timestamp" {
  description = "Static timestamp to keep the resource stable across runs"
  type        = string
  default     = "2026-05-06"
}
