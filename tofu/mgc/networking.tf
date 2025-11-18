resource "mgc_network_vpcs" "vpc" {
  name        = "vpc-${var.project}"
  description = "Nekoma VPC"
}

# Public Subnet
resource "mgc_network_subnetpools" "snet_pool" {
  name        = "snet-pool-pub-${var.project}"
  description = "Nekoma Subnet Pool"
  cidr        = "10.0.0.0/16"
}

resource "mgc_network_vpcs_subnets" "snet_pub" {
  cidr_block      = "10.0.1.0/24"
  description     = "Public VPC Subnet"
  ip_version      = "IPv4"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  name            = "snet-pub-${var.project}"
  subnetpool_id   = mgc_network_subnetpools.snet_pool.id
  vpc_id          = mgc_network_vpcs.vpc.id
}

# Create Security Group
resource "mgc_network_security_groups" "sg_vm" {
  name        = "sg-${var.project}"
  description = "Security group for the Nekoma server"
}

# Security Group Rule - SSH
resource "mgc_network_security_groups_rules" "allow_ssh" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow SSH access"
}

resource "mgc_network_security_groups_rules" "allow_http" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow HTTP access"
}

resource "mgc_network_security_groups_rules" "allow_https" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow HTTPS access"
}

resource "mgc_network_security_groups_rules" "allow_epmd_tcp" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 4369
  port_range_max    = 4369
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow EPMD port"
}

resource "mgc_network_security_groups_rules" "allow_epmd_udp" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "udp"
  ethertype         = "IPv4"
  port_range_min    = 4369
  port_range_max    = 4369
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow EPMD port"
}

resource "mgc_network_security_groups_rules" "allow_erlang_port_range" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 9100
  port_range_max    = 9155
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Extra ports for Erlang apps"
}

# Public IPs
resource "mgc_network_public_ips" "ip" {
  vpc_id = mgc_network_vpcs.vpc.id
}
