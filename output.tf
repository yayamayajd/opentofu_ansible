#out put the vpc_id
output "vpc_id" {
  description = "The ID of the VPC created for group_work"
  value       = aws_vpc.group_work.id
}

#output the pubsub ID
output "public_subnet1_id" {
  description = "The ID of the public subnet 1"
  value       = aws_subnet.public_sub1.id
}

output "public_subnet2_id" {
  description = "The ID of the public subnet 2"
  value       = aws_subnet.public_sub2.id
}

# output the prisub ID
output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_sub.id
}

# output alb name
output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.load_balancer.dns_name
}

# out put the first ec2 in pubsub IP
output "public_instance1_public_ip" {
  description = "Public IP address of the first web server"
  value       = aws_instance.public_instance1.public_ip
}

# out put the 2nd ec2 in pubsub IP
output "public_instance2_public_ip" {
  description = "Public IP address of the second web server"
  value       = aws_instance.public_instance2.public_ip
}

# out put the ec2 in prisub IP
output "private_db_instance_private_ip" {
  description = "Private IP address of the PostgreSQL server in the private subnet"
  value       = aws_instance.private_instance.private_ip
}

#out put ssh-key name
output "ssh_key_name" {
  description = "The SSH key name used for all EC2 instances"
  value       = aws_key_pair.deployer_key.key_name
}