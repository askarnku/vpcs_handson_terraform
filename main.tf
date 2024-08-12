# cloud provider
provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# vpc comprised of 2 subnets (public and private)
resource "aws_vpc" "vpc_a" {
  cidr_block = "10.100.0.0/16"
  tags = {
    Name = "vpc-a"
  }
}

# vpc comprised of 1 private subnet
resource "aws_vpc" "vpc_b" {
  cidr_block = "10.200.0.0/16"
  tags = {
    Name = "vpc-b"
  }
}

# create 2 subnets for vpc-a (public and private)
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

# create internet gateway for vpc-a public subnet
resource "aws_internet_gateway" "igw_public_sub" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "igw_public_sub"
  }
}

# create route table for vpc-a public subnet
resource "aws_route_table" "public_route_vpc_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "public_route_vpc_a"
  }
}

# create route for vpc-a public subnet
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_vpc_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_public_sub.id
}

# associate route table with public subnet
resource "aws_route_table_association" "pub_assoc" {
  route_table_id = aws_route_table.public_route_vpc_a.id
  subnet_id      = aws_subnet.public-subnet-vpc-a.id
}

# create route table for vpc-a private subnet
resource "aws_route_table" "private_route_vpc_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "private_route_vpc_a"
  }
}

# associate route table with private subnet
resource "aws_route_table_association" "priv_assoc" {
  route_table_id = aws_route_table.private_route_vpc_a.id
  subnet_id      = aws_subnet.private-subnet-vpc-a.id
}

# create route table for vpc-b private subnet
resource "aws_route_table" "private_route_vpc_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags = {
    Name = "private_route_vpc_b"
  }
}

# associate route table with private subnet
resource "aws_route_table_association" "priv_assoc_vpc_b" {
  route_table_id = aws_route_table.private_route_vpc_b.id
  subnet_id      = aws_subnet.private-subnet-vpc_b.id
}

# Create security group for public VPC-A subnet
resource "aws_security_group" "sg_public_subnet_vpc_a" {
  vpc_id      = aws_vpc.vpc_a.id
  name        = "sg_public_subnet_vpc_a"
  description = "Allow SSH inbound traffic from my ip"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"] 
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
  key_name        = var.private_key                                  # Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.sg_public_subnet_vpc_a.id]

  tags = {
    Name = "public_ec2"
  }

}

# create ec2 for vpc-a private subnet
resource "aws_instance" "vpc_a_private_ec2" {
  ami             = "ami-0ae8f15ae66fe8cda" # Replace with the appropriate AMI ID for your region
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private-subnet-vpc-a.id # Replace with your actual subnet ID
  key_name        = var.private_key
  vpc_security_group_ids = [aws_security_group.sg_private_subnet_vpc_a.id]
  tags = {
    Name = "private_ec2_vpc_a"
  }
}

# create ec2 for vpc-b private subnet
resource "aws_instance" "vpc_b_private_ec2" {
  ami             = "ami-0ae8f15ae66fe8cda" # Replace with the appropriate AMI ID for your region
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private-subnet-vpc_b.id # Replace with your actual subnet ID
  key_name        = var.private_key
  vpc_security_group_ids = [aws_security_group.sg_private_subnet_vpc_b.id]
  tags = {
    Name = "private_ec2_vpc_b"
  }
}

# create vpc peering connection between vpc-a and vpc-b
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true
}

# add route table rule for vpc-b private subnet to route traffic to vpc-a via peering connection
resource "aws_route" "vpc_b_to_vpc_a" {
  route_table_id         = aws_route_table.private_route_vpc_b.id
  destination_cidr_block = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# add route table rule for vpc-a private subnet to route traffic to vpc-b via peering connection
resource "aws_route" "vpc_a_to_vpc_b" {
  route_table_id         = aws_route_table.private_route_vpc_a.id
  destination_cidr_block = aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

