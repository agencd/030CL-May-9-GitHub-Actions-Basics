terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "CL030-DevOps"

    workspaces {
      name = "fred"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "prefix" {
  type        = string
  description = "Prefix for all resources"
  default     = "May-9"

}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# resource "aws_subnet" "public" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
#   tags = {
#     Name = "${var.prefix}-public-subnet"
#   }
# }

# resource "aws_subnet" "public_2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1b"
#   tags = {
#     Name = "${var.prefix}-public-subnet_2"
#   }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "${var.prefix}-igw"
#   }
# }

# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
#   tags = {
#     Name = "${var.prefix}-public-route-table"
#   }
# }

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "public_2" {
#   subnet_id      = aws_subnet.public_2.id
#   route_table_id = aws_route_table.public.id
# }

# module "sg" {
#   source  = "app.terraform.io/CL030-DevOps/security-groups-030/aws"
#   version = "3.0.0"
#   security_groups = {
#     "web-sg" = {
#       description = "Security group for web server"
#       vpc_id      = aws_vpc.main.id
#       ingress_rules = [
#         {
#           description = "HTTP"
#           from_port   = 80
#           to_port     = 80
#           protocol    = "tcp"
#           cidr_blocks = ["0.0.0.0/0"]
#           priority     = 200
#         },
#         {
#           description = "HTTPS"
#           from_port   = 443
#           to_port     = 443
#           protocol    = "tcp"
#           cidr_blocks = ["0.0.0.0/0"]
#           priority     = 202
#         }
#       ]
#       egress_rules = [
#         {
#           description = "Allow all outbound traffic"
#           from_port   = 0
#           to_port     = 0
#           protocol    = "-1"
#           cidr_blocks = ["0.0.0.0/0"]
#         }
#       ]    
#     }
#   }  
# }
# module "alb-sg" {
#   source  = "app.terraform.io/CL030-DevOps/security-groups-030/aws"
#   version = "3.0.0"
#   security_groups = {
#     "alb-sg" = {
#       description = "Security group for application load balancer"
#       vpc_id      = aws_vpc.main.id
#       ingress_rules = [
#         {
#           description = "HTTP"
#           from_port   = 80
#           to_port     = 80
#           protocol    = "tcp"
#           cidr_blocks = ["0.0.0.0/0"]
#           priority     = 200
#         },
#         {
#           description = "HTTPS"
#           from_port   = 443
#           to_port     = 443
#           protocol    = "tcp"
#           cidr_blocks = ["0.0.0.0/0"]
#           priority     = 202
#         }
#       ]
#       egress_rules = [
#         {
#           description = "Allow all outbound traffic"
#           from_port   = 0
#           to_port     = 0
#           protocol    = "-1"
#           cidr_blocks = ["0.0.0.0/0"]
#         }
#       ]    
#     }
#   }  
# }


# data "aws_ami" "amzn-linux-2023-ami" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.*-x86_64"]
#   }
# }

# resource "aws_key_pair" "deployer" {
#   key_name   = "deployer-key"
#   public_key = file("~/.ssh/id_ed25519.pub")
# }

# resource "aws_launch_template" "default" {
#   name_prefix = "${var.prefix}-launch-template-"
#   image_id = data.aws_ami.amzn-linux-2023-ami.id
#   instance_type = "t2.micro"
#   key_name = aws_key_pair.deployer.key_name
#   network_interfaces {
#     associate_public_ip_address = true
#     delete_on_termination       = true
#     subnet_id                  = aws_subnet.public.id
#     #security_groups            = [module.sg.security_groups["web-sg"].id]
#     security_groups            = [module.sg.security_group_ids["web-sg"]]
#   }
#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               sudo yum update -y
#               sudo yum install -y httpd
#               sudo systemctl start httpd.service
#               sudo systemctl enable httpd.service
#               AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
#               PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
#               echo "<h1> Availability Zone: $AZ, Public IP: $PUBLIC_IP </h1>" | sudo tee /var/www/html/index.html              
#             EOF
#           )
#   metadata_options {
#     http_endpoint = "enabled"
#     http_tokens   = "optional"
#   }
#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "${var.prefix}-web-instance"
#     }
#   }
# }

# resource "aws_autoscaling_group" "default" {
#   launch_template {
#     id      = aws_launch_template.default.id
#     version = "$Latest"
#   }
#   min_size           = 5
#   max_size           = 8
#   desired_capacity   = 5
#   vpc_zone_identifier = [aws_subnet.public.id , aws_subnet.public_2.id]
#   tag {
#     key                 = "Name"
#     value               = "${var.prefix}-web-instance-asg"
#     propagate_at_launch = true
#   }
#   target_group_arns = [ aws_lb_target_group.default.arn ]
# }

# resource "aws_lb" "default" {
#   name               = "test-lb-tf"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [module.alb-sg.security_group_ids["alb-sg"]]
#   subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]

#   enable_deletion_protection = false

# }

# resource "aws_lb_target_group" "default" {
#   name     = "${var.prefix}-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
#   target_type = "instance"

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

# # SSL = Secure Socket Layer
# resource "aws_lb_listener" "default" {
#   load_balancer_arn = aws_lb.default.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.default.arn
#   }
# }

# resource "aws_autoscaling_attachment" "asg_alb" {
#   autoscaling_group_name = aws_autoscaling_group.default.name
#   alb_target_group_arn   = aws_lb_target_group.default.arn
# }


