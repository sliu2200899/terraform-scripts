terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region                    = "us-east-1"
  shared_credentials_file   = "/Users/sliu/.aws/credentials"
  profile                   = "tomatols"
}

# 1. Create a VPC
resource "aws_vpc" "prod-vpc" {
 cidr_block = "172.16.0.0/16"

 tags = {
   Name = "production"
 }
}

# 2. Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-gw"
  }
}

# 3. Create a route
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-route"
  }
}


## 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
 vpc_id            = aws_vpc.prod-vpc.id
 cidr_block        = "172.16.10.0/24"
 availability_zone = "us-east-1a"

 tags = {
   Name = "prod-subnet"
 }
}


## 5. Associate subnet with Route Table 
resource "aws_route_table_association" "route-table-subnet" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

## 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   ### want everyone can access it
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   ### want everyone can access it
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   ### want everyone can access it
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"    ### -1 means any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


## 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["172.16.10.50"]
  security_groups = [aws_security_group.allow_web.id]
}

## 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "172.16.10.50"
  depends_on = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

## 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami           = "ami-013f17f36f8b1fefb"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "staging-home-v1"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
          #!/bin/bash
          sudo apt update -y
          sudo apt install apache2 -y
          sudo systemctl start apache2
          sudo bash -c 'echo your very first web server > /var/www/html/index.html'
          EOF
  
  tags = {
    Name = "web-server"
  }
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}