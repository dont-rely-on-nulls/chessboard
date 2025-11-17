variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "a"
  nullable    = false
}

# Use 't3.small' for local testing, due to the free-tier on
# certain regions.
variable "instance_type" {
  description = "The instance used by the AMI and EC2"
  type        = string
  default     = "t3a.medium"
  nullable    = false
}

variable "instance_root_volume_size_in_gb" {
  description = "The instance used by the AMI and EC2"
  type        = number
  default     = 200
  nullable    = false
}

variable "project" {
  type     = string
  default  = "trashcan"
  nullable = false
}

variable "region" {
  type     = string
  default  = "us-east-1"
  nullable = false
}

# ===============
# NixOS Variables
# ===============
variable "ami_version" {
  description = "NixOS AMI version"
  type        = string
  default     = "25.05"
  nullable    = false
}

variable "flake_path" {
  description = "NixOS flake URL (either a local path or git repo)"
  type        = string
  default     = "../.."
  nullable    = false
}

variable "flake_system" {
  description = "NixOS flake system to be use"
  type        = string
  default     = "bootstrap_aws"
  nullable    = false
}

