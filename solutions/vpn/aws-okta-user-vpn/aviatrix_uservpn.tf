resource "aviatrix_vpc" "vpn_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account_name
  region               = var.aws_region
  name                 = var.uservpn_vpc
  cidr                 = var.uservpn_vpc_cidr
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
}

resource "aviatrix_gateway" "vpn_gw1" {
  cloud_type       = 1
  account_name     = var.aws_account_name
  gw_name          = var.vpn_gw1_name
  vpc_id           = aviatrix_vpc.vpn_vpc.vpc_id
  vpc_reg          = var.aws_region
  gw_size          = var.vpn_gw1_size
  subnet           = var.vpn_gw1_subnet
  vpn_access       = true
  vpn_cidr         = var.vpn_gw1_vpn_cidr
  max_vpn_conn     = var.max_vpn_conn
  enable_elb       = var.enable_elb
  enable_vpn_nat   = var.enable_vpn_nat
  split_tunnel     = var.split_tunnel
  additional_cidrs = var.additional_cidrs
  saml_enabled     = var.saml_enabled
}

resource "aviatrix_gateway" "vpn_gw2" {
  cloud_type       = 1
  account_name     = var.aws_account_name
  gw_name          = var.vpn_gw2_name
  vpc_id           = aviatrix_vpc.vpn_vpc.vpc_id
  vpc_reg          = var.aws_region
  gw_size          = var.vpn_gw2_size
  subnet           = var.vpn_gw2_subnet
  vpn_access       = true
  vpn_cidr         = var.vpn_gw2_vpn_cidr
  max_vpn_conn     = var.max_vpn_conn
  enable_elb       = var.enable_elb
  enable_vpn_nat   = var.enable_vpn_nat
  split_tunnel     = var.split_tunnel
  additional_cidrs = var.additional_cidrs
  saml_enabled     = var.saml_enabled
}

# Create the SAML endpoint.
resource "aviatrix_saml_endpoint" "avx_saml_endpoint" {
  endpoint_name     = var.saml_endpoint_name
  idp_metadata_type = "Text"
  idp_metadata      = okta_app_saml.tf-uservpn.metadata
}

# Create the user with shared certificate, associated to the SAML endpoint.
resource "aviatrix_vpn_user" "vpn_user" {
  vpc_id        = aviatrix_vpc.vpn_vpc.vpc_id
  gw_name       = aviatrix_gateway.vpn_gw1.elb_name
  user_name     = var.vpn_user
  saml_endpoint = var.saml_endpoint_name
}

# Create the profile and associate the user to it.
resource "aviatrix_vpn_profile" "vpn_profile" {
  name      = var.vpn_profile_name
  base_rule = var.vpn_profile_base_rule
  users = [
    var.vpn_user
  ]

  policy {
    action = var.vpn_profile_policy1_action
    proto  = var.vpn_profile_policy1_proto
    port   = var.vpn_profile_policy1_port
    target = var.vpn_profile_policy1_target
  }

  policy {
    action = var.vpn_profile_policy2_action
    proto  = var.vpn_profile_policy2_proto
    port   = var.vpn_profile_policy2_port
    target = var.vpn_profile_policy2_target
  }
}
