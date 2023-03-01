# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "env_prefix" {}
variable "availability_zone" {}
variable "my_ip" {}
variable "instance-type" {}
variable "my_public_key_location" {
  
}

# Create a VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "dev-sub-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-route-table" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-internet-gateway.id
  }

  tags = {
    Name = "${var.env_prefix}-main-rt"
  }
}

resource "aws_default_security_group" "default-sg" {
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
    
  }
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

# data "aws_ami" "latest-AMI" {
#   most_recent = true
#   owners = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["Amazon Linux 2 AMI (HVM) - Kernel 4.14, SSD Volume Type"]
#   }


  
# }

# output "aws_ami_id" {
#   value = data.aws_ami.latest-AMI.id
  
# }

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.my_public_key_location)
  
}

resource "aws_instance" "myapp-server" {
  ami = "ami-006dcf34c09e50022"
  instance_type = var.instance-type
  subnet_id = aws_subnet.dev-sub-1.id
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  user_data = <<EOF
              #!/bin/bash

              sudo yum update -y
              sudo yum install docker -y

              # Start Docker service
              sudo systemctl start docker


              # Add the user to the Docker group
              sudo usermod -aG docker ec2-user

              # Start a new Nginx container
              sudo docker run -d -p 8080:80 nginx


              EOF

  tags = {
    "Name" = "${var.env_prefix}-server"
  }
}