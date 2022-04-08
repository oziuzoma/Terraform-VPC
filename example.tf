
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAUNKHVM7YDWV37FPX" 
  secret_key = "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"
}

resource "aws_vpc" "ozi" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MyFirstVPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ozi.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_internet_gateway_attachment" "example" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id              = aws_vpc.ozi.id
}

resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.ozi.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRT"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.ozi.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public1"
  }
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id     = aws_vpc.ozi.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public2"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.ozi.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "interface" {
  subnet_id   = aws_subnet.publicsubnet.id
  private_ips     = ["10.0.1.30"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_network_interface" "interface2" {
  subnet_id   = aws_subnet.publicsubnet2.id
  private_ips     = ["10.0.2.31"]
  security_groups = [aws_security_group.allow_web.id]
  
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.interface.id
  associate_with_private_ip = "10.0.1.30"
  depends_on = [aws_internet_gateway.gw]
  
}

resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.interface2.id
  associate_with_private_ip = "10.0.2.31"
  depends_on = [aws_internet_gateway.gw]
  
}


resource "aws_instance" "myserver" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "newkeypair"
 
  network_interface {
    network_interface_id = aws_network_interface.interface.id
    device_index         = 0
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y 
              sudo apt install apache2 -y 
              sudo systemctl start apache2
              sudo bash -c 'echo your first server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "web-server1"
  }

}

resource "aws_instance" "myserver2" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "newkeypair"

  network_interface {
    network_interface_id = aws_network_interface.interface2.id
    device_index         = 0
  }

  tags = {
    Name = "web-server2"
  }
}