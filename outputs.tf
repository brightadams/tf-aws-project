//print IP after creating ec2
output "ec2_public_ip" {
  value = module.myapp-server.instance.public_ip
}
