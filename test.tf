provider "aws" {            
region = "us-east-1"
version = "5.68.0"
}

provider "tls" {
version = "4.0.5"
}

provider "local" {
version = "2.5.0"
}


/* terraform {   to add s3 backend to sotre terraform.tfstate info in s3 bucket to visible to everyone
  backend "s3" {
    bucket = "4pmterraform"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
} */


resource "tls_private_key" "generated_key" {
algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
content = tls_private_key.generated_key.private_key_pem
filename = "terraform.pem"
}


resource "aws_vpc" "terraform_vpc" {
cidr_block = "10.0.0.0/16"
tags = {
Name = "terraform-vpc"
}
}

resource "aws_subnet" "terraform_subnet" {
vpc_id     = aws_vpc.terraform_vpc.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1b"
tags = {
Name = "terraform_vpc"
}
}

resource "aws_internet_gateway" "terraform_igw" {
vpc_id = aws_vpc.terraform_vpc.id
tags = {
Name = "terraform_igw"
}
}

resource "aws_route_table" "terraform_route" {
vpc_id = aws_vpc.terraform_vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.terraform_igw.id
}
tags = {
Name = "terraform_route"
}
}

resource "aws_route_table_association" "terraform_route_assoc" {
subnet_id = aws_subnet.terraform_subnet.id
route_table_id = aws_route_table.terraform_route.id
}

resource "aws_security_group" "terraform_sg" {
vpc_id = aws_vpc.terraform_vpc.id
ingress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "Terraformsg"
}
}

resource "aws_instance" "one" {
count = 10
ami = "ami-0ebfd941bbafe70c6"
instance_type = "t2.micro"
subnet_id = aws_subnet.terraform_subnet.id
tags = {
Name = "server-${count.index + 1}"
}
}
