# ===============
# MGC Variables
# ===============
variable "api_key" {
  type        = string
  sensitive   = true
  description = "The Magalu Cloud API Key"
}

variable "mgc_region" {
  description = "Specifies the region where resources will be created and managed."
  default     = "br-se1"
}

variable "project" {
  type     = string
  default  = "nekoma"
  nullable = false
}

# ===============
# VM Variables
# ===============
# Alternatives: BV1-2-100, BV2-4-100, BV4-8-100, etc.
variable "instance_type" {
  description = "Instance type for the VM"
  type        = string
  default     = "BV2-4-100"
}

variable "initial_image" {
  type    = string
  default = "cloud-ubuntu-24.04 LTS"
}

