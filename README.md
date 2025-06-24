DEPLOYING A WEBSERVER ON AWS USING TERRAFORM.

presquisites:
1) AWS Account
2) VS code or any IDE
3) Terraform installed  
4) AWS CLI installed. 

STEP1:
 -create a folder for your project on your local machine named "Deploy-Webserver-AWS-Terraform"  or give any name suitable for your project.
 -Go to vscode and open the folder created
 -Create these files inside the project folder provider.tf, main.tf, variable.tf (.tf represents the terraform file extension)

 STEP2:
  -Open provider.tf file and paste this below. This indicates the region which our resources will be created on AWS.

  provider "aws" {
  region = "us-east-1"
}
  

 STEP3:
 - Open the main.tf file. This file contain blocks of resources of our terraform code. Each block of it enables our web server to be deplpoyed and functioned properly as stated below in its sequential order;



#Ec2 instance created. 
#The Acces key to allow our ssh login is referenced as the variable  name "web-server-key"
#VPC id,subnet and others are referenced here too
#the user data consist of bash commands and our apache package to be installed on our web server alongside the message to be displayed when our server comes up, it will be directed to the file location of apache  package /var/www/html/index.hmtl


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



#VPC: A virtual private cloud that manage all our resources on AWS.

resource "aws_vpc" "web-server-vpc" {
  cidr_block = "10.0.0.0/16"
}




 #Internet gateway(IGW): to allow our resources like the Ec2 to coonect and access the internet


 resource "aws_internet_gateway" "web-server-gateway" {
  vpc_id = aws_vpc.web-server-vpc.id
  tags = {
    Name = "internet gateway"
  }
}


 #custom route table to control how traffic flows in the AWS network. it is referenced to our vpc

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




#subnet to place our EC2 instance in the VPC

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




#Security group to allow access to our server through the ssh rule,port 22 for server login, HTTP for internet access through port 80, HTTPS for secure login through port 443

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






#AWS Elastic Network interface referenced to our Subnet and security group

resource "aws_network_interface" "web-server-ENI" {
  subnet_id       = aws_subnet.web-server-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web-server-SG.id]
}

#ElasticIP to allow access to the internet and also maintain a consistent IP address for HTTP access for users.

resource "aws_eip" "web-server-ElasticIP" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-ENI.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_network_interface.web-server-ENI]
}







STEP4: 
-create an IAM user or add a user to a group with right permissions on AWS
Name; mywebserver
Attach policies directly
set policy as AMAZONEC2FULLACCESS, VPCFULLACCESS
Review and create
click on the user created, go to security credential
create Access key
select command line interface
give a tag(optional)
create access key
download the .csv file to  your local machine. This has the access key and the secret key that will enable us authenticate our terraform with our AWS account. Do not expose the seceret key on github repository or insert it on the terraform for best security practise.


STEP5;

- Run "Aws configure" on the terminal which has our terraform folder
- input the secret key, access key, the availabilty zone and select json to proceed


STEP6: 

- navigate to aws ec2 instance dashboard, create a key pair as .pem file. This will enbale us login to our server through ssh login.
- this key pair name was declared in our resource code(reference our instance block "key_name = web-server-key")


STEP7:
-open the terminal on vscode code
-run the below Terraform commands to authenticate our resouces and credentials to Aws.
Terraform init (this is to initialize our terraform code with our aws account)
Terraform plan (this displays the resources to be created and the details)
Terraform fmt (format the code)
TErraform validate (validates our code and also indicate syntax errors)
Terraform apply (pushes our artifacts  to Aws)


STEP8;
-Check the AWS console to see if all the resources are properly created
-accessing our server through the ssh login by running this command on the terminal
- chmod 400 web-server-key
- ssh -i downloads/web-server-key.pem @ubuntu3.142.445.63.

- Go to EC2 instance, copy the public ip address, paste it on the browser
- if the customized message is displayed
BOOM ! OUR WEB SERVER HAS BEEN SUCCESSFULLY DEPLOYED AND RUNNING.