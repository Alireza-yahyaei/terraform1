#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "private_key_path" {}
#variable "key_name" {}
#variable "region" {
#    default = "us-east-1"


terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>3.0"
        }
    }
}

#configure AWS provider
provider "aws" {
    region = "us-east-1"
}

#1Create a VPC
resource "aws_vpc" "test1" {
    cidr_block = "192.168.0.0/16"
    tags = {
      name = "DEV1"
    }
}

##2Create Internet GW
resource "aws_internet_gateway" "GW1" {
    vpc_id = aws_vpc.test1.id
  

}
##3Create Custom Routing Table
resource "aws_route_table" "RT1" {
    vpc_id = aws_vpc.test1.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW1.id
  }
  
  tags = {
    name = "DEV1"
  }
}
##4 Create Subnet
resource "aws_subnet" "Sub1" {
    vpc_id = aws_vpc.test1.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
      "name" = "DEV-Subnet"
    }
  
}
##5Associate Subnet With Routing Table
resource "aws_route_table_association" "RTAs" {
  subnet_id = aws_subnet.Sub1.id
  route_table_id = aws_route_table.RT1.id
}
##6 Create Security Groups to allow 22,80,443
resource "aws_security_group" "SG1" {
  name = "Allow_traffice"
  description = "Traffice allow"
  vpc_id = aws_vpc.test1.id
  ingress {
    description = "https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "name" = "allow_web"
  }
}
##7 Creat a network interface
resource "aws_network_interface" "nic1" {
  subnet_id = aws_subnet.Sub1.id
  private_ips = ["192.168.1.10"]
  security_groups = [aws_security_group.SG1.id]

}

##8 Assign Elastic IP
resource "aws_eip" "Eip1" {
vpc = true
network_interface = aws_network_interface.nic1.id
associate_with_private_ip = "192.168.1.10"
depends_on = [aws_internet_gateway.GW1]
  
}
output "server_public_dns" {
    value = aws_eip.Eip1.public_ip
  
}
##9 Create Ubuntu
resource "aws_instance" "Server1" {
    ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "plan1"
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.nic1.id
    }
    
  tags = {
    "name" = "web-server"
  }
  connection {
    type  = "ssh"
    host  = self.public_ip
    user  ="ec2-user"
    private_key  = "/Users/user1/learning1/plan1.pem"

    
  }
  provisioner "remote-exec" {
  inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo rm /usr/share/nginx/html/index.html",
      "echo '<html><head><title>ALIREZA</title></head><body>Hello World!</body></html>' | sudo tee /usr/share/nginx/html/index.html"

  ]
}
}

output "server_private_ip" {
  value = aws_instance.Server1.private_ip

}
output "Server_id" {
    value = aws_instance.Server1.id
  
}