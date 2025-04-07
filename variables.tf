variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
}

variable "ami_id" {
    description = "Amazon Machine Image ID"
    type        = string
    default     = "ami-05b10e08d247fb927"
}

variable "instance_type" {
    description = "The tyoe of EC2 instance"
    type        = string
    default     = "t2.micro"
}

variable "key_name" {
    description = "ssh keypaire for ec2s"
    type        = string
}

variable "public_key_path" {
    description = "IP-adresses of the public key"
    type        = string 
}

variable "truste_ip_for_ssh" {
    description = "the public adresser allow to be ssh"
    type        = list
}

variable "vpc_cidr" {
    description = "VPC cidr block, should contain all the subnets"
    type        = string
    default     = "10.0.0.0/16"
}

variable "public_subnet_cidr1" {
    description = "the public subnet 1 cidr block"
    type        =string
}

variable "public_subnet_cidr2" {
    description = "the public subnet 2 cidr block"
    type        =string
}

variable "private_subnet_cidr" {
    description = "the public subnet cidr block"
    type        = string
}

