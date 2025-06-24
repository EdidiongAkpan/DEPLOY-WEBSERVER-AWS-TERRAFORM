resource "aws_instance" "web-server" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name      = "web-server-key"
  vpc_security_group_ids = [aws_security_group.web-server-SG.id]
  subnet_id = aws_subnet.web-server-subnet.id
  associate_public_ip_address = true

  user_data = <<-EOF
        #!/bin/bash 
        sudo apt update -y
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo systemctl enable apache2
        sudo bash -c 'echo My web server was successfully deployed!> /var/www/html/index.html'
        EOF

  tags = {
    Name = "web server"
  }
}

#vpc

resource "aws_vpc" "web-server-vpc" {
  cidr_block = "10.0.0.0/16"
}

#internet gateway(IGW)

resource "aws_internet_gateway" "web-server-gateway" {
  vpc_id = aws_vpc.web-server-vpc.id
  tags = {
    Name = "internet gateway"
  }
}

#custom route table

resource "aws_route_table" "web-server-route-table" {
  vpc_id = aws_vpc.web-server-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-server-gateway.id
  }

  tags = {
    Name = "my route table"
  }
}

#subnet

resource "aws_subnet" "web-server-subnet" {
  vpc_id            = aws_vpc.web-server-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "web server subnet"
  }
}

#Associate subnet with The Route Table

resource "aws_route_table_association" "Server-Route-Table" {
  subnet_id      = aws_subnet.web-server-subnet.id
  route_table_id = aws_route_table.web-server-route-table.id
}

#Security group 

resource "aws_security_group" "web-server-SG" {
  name        = "web-server-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.web-server-vpc.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#AWS Elastic Network interface referenced to our Subnet

resource "aws_network_interface" "web-server-ENI" {
  subnet_id       = aws_subnet.web-server-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web-server-SG.id]
}

#ElasticIP to allow access to the internet

resource "aws_eip" "web-server-ElasticIP" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-ENI.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_network_interface.web-server-ENI]
}
