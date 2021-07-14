provider "aws" {
  region = "eu-west-1"
}

variable "env" {
  type    = string
  default = "dev"
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    Name = "${var.env}-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env}-igw"
  }
}

# Subnets
## Public
### AZ1
resource "aws_subnet" "subnet-public-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "${var.env}-subnet-public-1"
  }
}

## Private
### AZ1
resource "aws_subnet" "subnet-private-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.99.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "${var.env}-subnet-private-1"
  }
}

# Nat Instance
#resource "aws_instance" "nat" {
#  ami                    = "ami-0f630a3f40b1eb0b8"
#  instance_type          = "t2.micro"
#  subnet_id              = aws_subnet.subnet-public-1.id
#  vpc_security_group_ids = [aws_security_group.allow_nat.id]
#  source_dest_check      = "false"

#  user_data = <<-EOF
#        #!/bin/bash
#        sysctl -w net.ipv4.ip_forward=1 /sbin/
#        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#  EOF

#  tags = {
#    Name = "${var.env}-NatInstance"
#  }
#}

## SG Rule chat_server_sg
resource "aws_security_group" "chat_server_sg" {

  name        = "chat_server_sg"
  description = "Allow TCP 5555 & SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  
  ingress {
    description      = "5555 from EFREI_GROUP"
    from_port        = 5555
    to_port          = 5555
    protocol         = "tcp"
    cidr_blocks      = ["82.64.73.178/32","90.3.0.106/32","176.158.166.180/32","80.215.38.198/32","10.0.4.0/32","10.0.4.0/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

## SG Rule ingress
#resource "aws_security_group_rule" "ingress_allow_private" {
#  type              = "ingress"
#  from_port         = 0
#  to_port           = 0
#  protocol          = -1
#  cidr_blocks       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#  security_group_id = aws_security_group.allow_nat.id
#}

# Route Table
## Private
### Use Main Route Table
resource "aws_default_route_table" "main-private" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.env}-rt-main-private"
  }
}

## Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-rt-public"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public-1" {
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public.id
}