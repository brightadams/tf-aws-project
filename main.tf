provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet" {
  source = "./modules/subnet"
  //so we fill in the inputs here, which takes the values from .tfvars file
  subnet_cidr_block      = var.subnet_cidr_block
  avail_zone             = var.avail_zone
  env_prefix             = var.env_prefix
  vpc_id                 = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

/*
//security group rules
resource "aws_security_group" "myapp-sg" {
  name = "mya--sg"
  //attach the security group to the vpc
  vpc_id = aws_vpc.myapp-vpc.id
  //incoming traffic rules here
  ingress {
    //from_port and to_port means we can get a range of IPs, but since we need just one we set the 2 to the same port
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    //we define the ips that can send traffic to the port specified.. it is a cidr block so use /32, you can 0.0.0.0/0 if you want to accept traffic from everywhere
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    // 0 for from and to port means any port, and -1 for protocol means any protocol.. Because we will want the ec2 server to be able to download docker, pull images and stuff and we do not know the port and protocol it will require
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-sg"
  }
}
*/

module "myapp-server" {
  source              = "./modules/webserver"
  vpc_id              = aws_vpc.myapp-vpc.id
  my_ip               = var.my_ip
  image_name          = var.image_name
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
  subnet_id           = module.myapp-subnet.subnet.id
  avail_zone          = var.avail_zone
  env_prefix          = var.env_prefix

}
