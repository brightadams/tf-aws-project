provider "aws" {
  region = "eu-west-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  //attaching the igw the vpc
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name : "${var.env_prefix}-igw"
  }
}

/*
//create route table so you can communicate within the vpc and the internet
resource "aws_route_table" "myapp-route-table" {
  //creating the route table in the vpc
  vpc_id = aws_vpc.myapp-vpc.id

  //set up route table to be able to communicate with the internet using igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name : "${var.env_prefix}-rtb"
  }
}
*/

/*
//associate the route table to a subnet so we can control traffic in from ro the subnet
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
*/

//we get a default route table when we create a vpc, we can use this to connect to the internet rather than creating a new route table and subnet associations in the above 
resource "aws_default_route_table" "main-rtb" {
  //terraform state show aws_vpc.myapp-vpc ; to view the default route table id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
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

//aws creates a default security group just like the default route tables, so we do not have to create one as we did above
resource "aws_default_security_group" "default-sg" {
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
    Name : "${var.env_prefix}-default-sg"
  }
}

//since ami names change all the time, we must give a regex for the imge and owner of the ami
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



//creating keypair file
resource "aws_key_pair" "ssh-key" {
  key_name = "server_key"
  //key is created by doing ssh-keygen, cat ~/.ssh/id_rsa.pub to get the public key
  public_key = file(var.public_key_location)
}

//creating ec2 instance
resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  //we attach the ec2 to our vpc, subnet and security groups created
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone      = var.avail_zone
  //associate public api address so we can ssh into it
  associate_public_ip_address = true
  /*
  //add keypair name file that can be used to do ssh.. this must be created in aws before
  key_name = "tf-server-keypair"
  */
  //add keypair after creating it
  //if you use the id_rsa.pub, you will ssh by doing; ssh ec2-user@Ip.Addr.ess
  key_name = aws_key_pair.ssh-key.key_name
  //below user data is not working so cant run the docker..
  user_data = file("entry-script.sh")

  tags = {
    Name : "${var.env_prefix}-server"
  }
}


//print AMI used
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

//print IP after creating ec2
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}
