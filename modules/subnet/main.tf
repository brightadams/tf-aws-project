resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  //attaching the igw the vpc
  vpc_id = var.vpc_id
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
  default_route_table_id = var.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
}
