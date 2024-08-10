provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_a" {
  cidr_block = "10.100.0.0/16"
  tags = {
    Name = "vpc-a"
  }
}

resource "aws_vpc" "vpc_b" {
  cidr_block = "10.200.0.0/16"
  tags = {
    Name = "vpc-b"
  }
}

# create 2 subnets for vpc-a
resource "aws_subnet" "public-subnet-vpc-a" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.100.10.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-vpc-a"
  }
}

resource "aws_subnet" "private-subnet-vpc-a" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.100.20.0/24"
  tags = {
    Name = "private-subnet-vpc-a"
  }
}

# create 1 private subnet for vpc-b
resource "aws_subnet" "private-subnet-vpc_b" {
  vpc_id     = aws_vpc.vpc_b.id
  cidr_block = "10.200.10.0/24"
  tags = {
    Name = "private-subnet-vpc_b"
  }
}

resource "aws_internet_gateway" "igw_public_sub" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "igw_public_sub"
  }
}

resource "aws_route_table" "public_route_vpc_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "public_route_vpc_a"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_vpc_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_public_sub.id
}

resource "aws_route_table_association" "pub_assoc" {
  route_table_id = aws_route_table.public_route_vpc_a.id
  subnet_id = aws_subnet.public-subnet-vpc-a.id
}

# create instances on each vpc
# -- configure security groups
# vpc-a public subnet ingress and egress rules: Allow ssh traffic on port 22 outbound on all traffic

# Create security group for public VPC-A subnet
resource "aws_security_group" "public_subnet_instance_vpc_a" {
  name        = "allow_tls_for_public"
  description = "Allow TLS inbound traffic from myip and all outbound traffic"
  vpc_id      = aws_vpc.vpc_a.id

    lifecycle {
    create_before_destroy = false  # We want to destroy the existing SG before creating a new one
  }

  tags = {
    Name = "sg-vpc-a-public-subnet"
  }
}

# Ingress rule allowing traffic from a specific IP address (SSH as an example)
resource "aws_security_group_rule" "inbound_myip" {
  type              = "ingress"
  security_group_id = aws_security_group.public_subnet_instance_vpc_a.id
  cidr_blocks       = ["73.22.26.89/32"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

# Egress rule allowing all outbound traffic
resource "aws_security_group_rule" "outbound_to_all" {
  type              = "egress"
  security_group_id = aws_security_group.public_subnet_instance_vpc_a.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 10000
  protocol          = "-1"
}

# create security group for private sub in vpc-a
resource "aws_security_group" "private_subnet_instance_vpc-a" {
  name        = "allow_tls_for_private"
  description = "Allow TLS inbound traffic from vpc-a public sub"
  vpc_id = aws_vpc.vpc_a.id

    lifecycle {
    create_before_destroy = false  # We want to destroy the existing SG before creating a new one
  }

  tags = {
    Name = "sg-vpc-a-private-subnet"
  }
}

resource "aws_vpc_security_group_ingress_rule" "inbound_from_vpc_a_public" {
  security_group_id = aws_security_group.private_subnet_instance_vpc-a.id
  cidr_ipv4         = "10.100.1.0/24"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "outboudn_to_vpc_b" {
  security_group_id = aws_security_group.private_subnet_instance_vpc-a.id
  cidr_ipv4         = "10.200.10.0/24"
  ip_protocol       = "-1"
}

