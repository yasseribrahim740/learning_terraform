
resource "aws_default_security_group" "default-sg" {
  vpc_id      = var.vpc_id

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



resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.my_public_key_location)
  
}

resource "aws_instance" "myapp-server" {
  ami = var.iam
  instance_type = var.instance-type
  subnet_id = var.subnet_id
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

