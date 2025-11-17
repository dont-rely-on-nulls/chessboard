variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "a"
  nullable    = false
}

# Use 't3.small' for some quick testing, due to the free-tier
# on certain regions.
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

# Change this to 'us-east-1' for quick testing
variable "region" {
  type     = string
  default  = "sa-east-1"
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

