# Variables
## Subnets
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr_block" {
  default = "10.0.1.0/24"
}

variable "ssh_user" {
  default = "openvpnas"
}

## Security Group
variable "ssh_port" {
  default = 22
}

variable "ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "https_port" {
  default = 443
}

variable "https_cidr" {
  default = "0.0.0.0/0"
}

variable "http_port" {
  default = 80
}

variable "http_cidr" {
  default = "0.0.0.0/0"
}

variable "tcp_port" {
  default = 943
}

variable "tcp_cidr" {
  default = "0.0.0.0/0"
}

variable "udp_port" {
  default = 1194
}

variable "udp_cidr" {
  default = "0.0.0.0/0"
}

## Domain
variable "route53_zone_name" {}
variable "subdomain_name" {}

variable "subdomain_ttl" {
  default = "60"
}
variable "certificate_email" {}


## VPN
variable "ami" {
  default = "ami-0a61576f" // ubuntu xenial  ami in us-east-2
}

variable "instance_type" {
  default = "t2.medium"
}

variable "admin_user" {
  default = "openvpn"
}

variable "admin_password" {
  default = "openvpn"
}


# VPC and Subnetting
resource "aws_vpc" "demo_environment" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "demo_environment"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.demo_environment.id}"
  cidr_block = "${var.public_subnet_cidr_block}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags {
    Name = "demo_environment"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.demo_environment.id}"
  cidr_block = "${var.private_subnet_cidr_block}"
  availability_zone = "us-east-1a"
  tags {
    Name = "demo_environment"
  }
}


# Gateway and NAT and associated nonsense
## Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.demo_environment.id}"
}

## NAT
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_subnet.id}"
}

# Routing
## Public Subnet Routing
resource "aws_route_table" "public_routetable" {
  vpc_id = "${aws_vpc.demo_environment.id}"

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
  tags {
    Name = "demo_environment"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_routetable.id}"
}

## Private Subnet Routing
resource "aws_route_table" "private_routetable" {
  vpc_id = "${aws_vpc.demo_environment.id}"
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
  tags {
    Name = "demo_environment"
  }
}

resource "aws_route_table_association" "private_subnet" {
  subnet_id = "${aws_subnet.private_subnet.id}"
  route_table_id = "${aws_route_table.private_routetable.id}"
}

# Openvpn Provisioning
## Keypair
variable "public_key" {}

variable "private_key" {}

resource "aws_key_pair" "openvpn" {
key_name  = "openvpn-key"
  public_key = "${file("${path.cwd}/${var.public_key}")}"
}

## Security Group
resource "aws_security_group" "openvpn" {
  name        = "openvpn_sg"
  description = "Allow traffic needed by openvpn"
  vpc_id      = "${aws_vpc.demo_environment.id}"

  ### ssh
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_cidr}"]
  }

  ### https
  ingress {
    from_port   = "${var.https_port}"
    to_port     = "${var.https_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.https_cidr}"]
  }

  ### http for letsencrypt
  ingress {
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.http_cidr}"]
  }

  ### open vpn tcp
  ingress {
    from_port   = "${var.tcp_port}"
    to_port     = "${var.tcp_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.tcp_cidr}"]
  }

  ### open vpn udp
  ingress {
    from_port   = "${var.udp_port}"
    to_port     = "${var.udp_port}"
    protocol    = "udp"
    cidr_blocks = ["${var.udp_cidr}"]
  }

  ### all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Setup domain
data "aws_route53_zone" "main" {
  name = "${var.route53_zone_name}"
}

resource "aws_route53_record" "vpn" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.subdomain_name}"
  type    = "A"
  ttl     = "${var.subdomain_ttl}"
  records = ["${aws_instance.openvpn.public_ip}"]
}

## Actual Resource
resource "aws_instance" "openvpn" {
  tags {
    Name = "openvpn"
  }

  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.openvpn.key_name}"
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  associate_public_ip_address = true

  user_data = <<USERDATA
admin_user=${var.admin_user}
admin_pw=${var.admin_password}
USERDATA
}

## Provision Server and generate cert with let's encrypt
resource "null_resource" "provision_openvpn" {
  triggers {
    subdomain_id = "${aws_route53_record.vpn.id}"
  }

  connection {
    type        = "ssh"
    host        = "${aws_instance.openvpn.public_ip}"
    user        = "${var.ssh_user}"
    port        = "${var.ssh_port}"
    private_key = "${file("${path.cwd}/${var.private_key}")}"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y curl vim libltdl7 python3 python3-pip python software-properties-common unattended-upgrades",
      "sudo add-apt-repository -y ppa:certbot/certbot",
      "sudo apt-get -y update",
      "sudo apt-get -y install certbot",
      "sudo service openvpnas stop",
      "sudo certbot certonly --standalone --non-interactive --agree-tos --email ${var.certificate_email} --domains ${var.subdomain_name} --pre-hook 'service openvpnas stop' --post-hook 'service openvpnas start'",
      "sudo ln -s -f /etc/letsencrypt/live/${var.subdomain_name}/cert.pem /usr/local/openvpn_as/etc/web-ssl/server.crt",
      "sudo ln -s -f /etc/letsencrypt/live/${var.subdomain_name}/privkey.pem /usr/local/openvpn_as/etc/web-ssl/server.key",
      "sudo service openvpnas start",
    ]
  }
}
