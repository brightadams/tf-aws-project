//to be able to use the values of the created resource you must export it as an output..
output "subnet" {
  value = aws_subnet.myapp-subnet-1
}
