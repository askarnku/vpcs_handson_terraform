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
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.100.10.0/24"
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