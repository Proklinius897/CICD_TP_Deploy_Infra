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
