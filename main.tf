#all the resource neend to clarify the other resource id when they call the api
#the grammer is :resource_type.resource_name.id
#the id generate aotumatically when the resource been created



#provider


terraform {
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
      default_tags {
    tags = {
      Project     = "group_work"
    }
  }
} 

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name = "name"
        values = ["al2023-ami-*"]
    }
}


#instance

resource "aws_instance" "public_instance1" {
    ami             = data.aws_ami.amazon_linux.id
    instance_type   = var.instance_type
    subnet_id       = aws_subnet.public_sub1.id
    key_name        = var.key_name
    vpc_security_group_ids = [aws_security_group.public_sg.id]
    associate_public_ip_address = true
}

resource "aws_instance" "public_instance2" {
    ami             = data.aws_ami.amazon_linux.id
    instance_type   = var.instance_type
    subnet_id       = aws_subnet.public_sub2.id
    key_name        = var.key_name
    vpc_security_group_ids = [aws_security_group.public_sg.id]
    #associate_public_ip_address = true if use the map_public_ip_on_launch, then don't need to clarify this
}

resource "aws_instance" "private_instance" {
    ami             = data.aws_ami.amazon_linux.id
    instance_type   = var.instance_type
    subnet_id       = aws_subnet.private_sub.id
    key_name        = var.key_name
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    associate_public_ip_address = false
}




#ssh key
#after checked the risk seems the generate ssh manually is better
resource "aws_key_pair" "deployer_key" {
    key_name = var.key_name
    public_key = file(var.public_key_path)
}



#resource: vpc

resource "aws_vpc" "group_work" {
    cidr_block = var.vpc_cidr
}


resource "aws_subnet" "public_sub1" {
    vpc_id      = aws_vpc.group_work.id
    cidr_block  = var.public_subnet_cidr1
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "public_sub2" {
  vpc_id                  = aws_vpc.group_work.id
  cidr_block  = var.public_subnet_cidr2
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_sub" {
    vpc_id      = aws_vpc.group_work.id
    cidr_block  = var.private_subnet_cidr
}




#network
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.group_work.id

}


#security group

resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "for HTTP and SSH inbound"
  vpc_id      = aws_vpc.group_work.id

  ingress {
    description = "for ssh from trusted ip (cloudshell)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.truste_ip_for_ssh #if need to use ansible directly on my pc, need to allow my own adress
  }

  ingress {
    description = "Allow HTTP from anywhere to ALB (if needed)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "for HTTP flask"
    from_port   = 5000 #change to flask port
    to_port     = 5000 #change to flask port
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

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "allow web server visit db"
  vpc_id      = aws_vpc.group_work.id

  ingress {
    description = "allow all web server in same vpc visit db"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.group_work.cidr_block]
  }

  ingress {
    description = "allow SSH from public_sg"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#to tie the subnet and route table, need to use the assoxiation. it's like the relation table in databse, to connet eachother
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.group_work.id

  route {
    cidr_block = "0.0.0.0/0" #allow all the traffic go out from vpc
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_ass" {
  subnet_id = aws_subnet.public_sub1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_ass_2" {
  subnet_id      = aws_subnet.public_sub2.id
  route_table_id = aws_route_table.public_rt.id
}


#ALB(coutains 4 esencial part resource: LB, target group, target group attachment, listener)
resource "aws_lb" "load_balancer" {
  name                = "group-work-alb"
  internal            = false

  load_balancer_type  = "application"
  security_groups     = [aws_security_group.public_sg.id]
  subnets             = [aws_subnet.public_sub1.id,aws_subnet.public_sub2.id]
  enable_deletion_protection = false
  
}

resource "aws_lb_target_group" "web_tg" {
  name      = "group-work-tg"
  port      = 80 #can keep 80 as default, because aws will prioritize the attachment port first
  protocol  = "HTTP"
  vpc_id    = aws_vpc.group_work.id

  health_check {
    enabled  = true
    interval = 30
    path     = "/"
    protocol = "HTTP"
    port     = 80     
  }
}

resource "aws_lb_target_group_attachment" "tg_web1" {
  target_group_arn  = aws_lb_target_group.web_tg.arn
  target_id         = aws_instance.public_instance1.id
  port              = 5000 #while visit with alb, use the domain name. other wise use ip+port 5000
}

resource "aws_lb_target_group_attachment" "tg_web2" {
  target_group_arn  = aws_lb_target_group.web_tg.arn
  target_id         = aws_instance.public_instance2.id
  port              = 5000
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.group_work.id
}

resource "aws_route" "private_nat_gateway_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_rt_ass" {
  subnet_id = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_sub1.id  # NAT Gateway shoul be in the pubsub

  depends_on = [aws_internet_gateway.igw]  # make sure create igw first
}









