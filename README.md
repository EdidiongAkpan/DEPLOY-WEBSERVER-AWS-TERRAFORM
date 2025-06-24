
# Deploying a Web Server on AWS Using Terraform

# Prerequisites

- AWS Account  
- VS Code or any IDE  
- Terraform installed  
- AWS CLI installed  



# Step 1: Set Up Your Project

1. Create a folder for your project (Deploy-Webserver-AWS-Terraform).
2. Open the folder on VS Code.
3. Inside the project folder, create the following files:
   - `provider.tf'
   -  main.tf
   - variable.tf



## Step 2: Configure the AWS Provider

Open provider.tf and paste the following code. This sets the AWS region where your resources will be created:

provider "aws" {
  region = "us-east-1"
}



# Step 3: Define Resources in `main.tf`

This file contains the Terraform resource blocks.

# EC2 Instance

resource "aws_instance" "web-server" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.micro"
  key_name                    = "web-server-key"
  vpc_security_group_ids      = [aws_security_group.web-server-SG.id]
  subnet_id                   = aws_subnet.web-server-subnet.id
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo bash -c 'echo My web server was successfully deployed! > /var/www/html/index.html'
              EOF

  tags = {
    Name = "web server"
  }
}


# VPC

resource "aws_vpc" "web-server-vpc" {
  cidr_block = "10.0.0.0/16"
}


# Internet Gateway

resource "aws_internet_gateway" "web-server-gateway" {
  vpc_id = aws_vpc.web-server-vpc.id

  tags = {
    Name = "internet gateway"
  }
}


# Route Table

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


#Subnet

resource "aws_subnet" "web-server-subnet" {
  vpc_id            = aws_vpc.web-server-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "web server subnet"
  }
}

# Route Table Association

resource "aws_route_table_association" "Server-Route-Table" {
  subnet_id      = aws_subnet.web-server-subnet.id
  route_table_id = aws_route_table.web-server-route-table.id
}

# Security Group

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

# Network Interface

resource "aws_network_interface" "web-server-ENI" {
  subnet_id       = aws_subnet.web-server-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web-server-SG.id]
}


# Elastic IP

resource "aws_eip" "web-server-ElasticIP" {
  domain                   = "vpc"
  network_interface        = aws_network_interface.web-server-ENI.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [aws_network_interface.web-server-ENI]
}


## Step 4: Create IAM User and Access Key

1. Go to AWS IAM.
2. Create a new user named `mywebserver` with these roles:
   - AmazonEC2FullAccess
   - AmazonVPCFullAccess
3. Create access key for CLI access.
4. Download the `.csv` file containing the credentials.


## Step 5: Configure AWS CLI

Run this in your terminal (inside your project folder):

'aws configure'

Input:

- Access key ID  :
- Secret access key:  
- Region (us-east-1 ) 
- Output format (json)


## Step 6: Create SSH Key Pair

1. In AWS EC2 Dashboard, create a new key pair (`.pem` format).
2. Name it web-server-key.
3. This matches the value used in the Terraform EC2 resource block.


## Step 7: Run these Terraform Commands

In the terminal, run the following:

1.terraform init          
2.terraform plan         
3.terraform fmt 
4.erraform validate       
5.terraform apply     


## Step 8: Verify Deployment

1. Go to the AWS Console and verify the resources.
2. To SSH into your server:

chmod 400 web-server-key.pem
ssh -i web-server-key.pem ubuntu@<your-ec2-public-ip>

3. Copy your EC2 public IP and paste it in the browser.

If you see the custom Apache message, BOOM! Our web server has been successfully deployed!



We have successfully deployed a web server on AWS using Terraform.
