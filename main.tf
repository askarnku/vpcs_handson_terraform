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
  subnet_id      = aws_subnet.public-subnet-vpc-a.id
}

# create instances on each vpc
# -- configure security groups
# vpc-a public subnet ingress and egress rules: Allow ssh traffic on port 22 outbound on all traffic

# Create security group for public VPC-A subnet
resource "aws_security_group" "sg_public_subnet_vpc_a" {
  vpc_id      = aws_vpc.vpc_a.id
  name        = "sg_public_subnet_vpc_a"
  description = "Allow SSH inbound traffic from my ip"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.22.26.89/32"] # Open to the world (use carefully)
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" # Allow all outbound traffic
    cidr_blocks = ["10.100.20.0/24"]
  }

  tags = {
    Name = "sg_public_subnet"
  }
}

# create security group for private sub in vpc-a
resource "aws_security_group" "sg_private_subnet_vpc_a" {
  vpc_id      = aws_vpc.vpc_a.id
  name        = "sg_private_subnet_vpc_a"
  description = "Allow SSH inbound traffic from my ip"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.100.10.0/24"] # Open to the world (use carefully)
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" # Allow all outbound traffic
    cidr_blocks = ["10.200.10.0/24"]
  }

  tags = {
    Name = "sg_private_subnet_vpc_a"
  }
}

resource "aws_security_group" "sg_private_subnet_vpc_b" {
  vpc_id      = aws_vpc.vpc_b.id
  name        = "sg_private_subnet_vpc_b"
  description = "Allow SSH inbound traffic from my ip"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.100.20.0/24"] # Open to the world (use carefully)
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" # Allow all outbound traffic
    cidr_blocks = ["10.100.20.0/24"]
  }

  tags = {
    Name = "sg_private_subnet_vpc_b"
  }
}

#create EC2 instance for vpc-a public
# Create an EC2 Instance
resource "aws_instance" "vpc_a_public_ec2" {
  ami             = "ami-0ae8f15ae66fe8cda" # Replace with the appropriate AMI ID for your region
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public-subnet-vpc-a.id            # Replace with your actual subnet ID
  key_name        = "id_ed25519"                                   # Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.sg_public_subnet_vpc_a.id]

  tags = {
    Name = "public_ec2"
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_instance" "vpc_a_private_ec2" {
  ami             = "ami-0ae8f15ae66fe8cda" # Replace with the appropriate AMI ID for your region
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private-subnet-vpc-a.id # Replace with your actual subnet ID
  key_name        = "id_ed25519"
  vpc_security_group_ids = [aws_security_group.sg_private_subnet_vpc_a.id]
  tags = {
    Name = "private_ec2_vpc_a"
  }

  lifecycle {
    prevent_destroy = false
  }

}
