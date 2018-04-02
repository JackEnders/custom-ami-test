aws_profile_name = "default"

aws_region = "us-east-1"

ami = "ami-548e4429" # Openvpn connect ami, make sure it matches your region

public_key = "openvpn-key.pub" #Path relative to main.tf

private_key = "openvpn-key" #Path Relative to main.tf

certificate_email = "mail@example.com"

route53_zone_name = "domain.test." # The period at the end is key

subdomain_name = "vpn.domain.test" #Any subdomain, no period

# vpc_cidr_block = "10.0.0.0/16"
# subnet_cidr_block = "10.0.0.0/16"
# ssh_port = 22
# ssh_cidr = "0.0.0.0/0"
# https_port = 443
# https_cidr = "0.0.0.0/0"
# http_port = 80
# http_cidr = "0.0.0.0/0"
# tcp_port = 943
# tcp_cidr = "0.0.0.0/0"
# udp_port = 1194
# udp_cidr = "0.0.0.0/0"
# subdomain_ttl = 60
# instance_type = "t2.medium"
# admin_user = "openvpn"
#admin_password = "not_openvpn"
