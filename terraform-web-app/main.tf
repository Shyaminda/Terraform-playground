terraform {
	backend "s3" {
		bucket = "terraform-state-bucket-shyaminda"
		key = "terraform-playground/terraform-web-app/terraform.tfstate"
		region = "us-east-1"
		dynamodb_table = "terraform-state-locking"
		encrypt = true
	}

	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_instance" "ec2_instance_1" {
	ami = "ami-0c398cb65a93047f2"    //Amazon Ubuntu Server 22.04 LTS, x86_64, free-tier eligible
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance.name]
	user_data = <<-EOF
			#!/bin/bash
			apt update -y
			apt install -y python3

			echo "Hello from Terraform instance NO. 1!" > /var/www/html/index.html
			
			mkdir -p /var/www/html
			cd /var/www/html
			python3 -m http.server 3000 &
			EOF
}

resource "aws_instance" "ec2_instance_2" {
	ami = "ami-0c398cb65a93047f2"  //Amazon Ubuntu Server 22.04 LTS, x86_64, free-tier eligible
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance.name]
	user_data = <<-EOF
			#!/bin/bash
			apt update -y
			apt install -y python3

			echo "Hello from Terraform instance NO. 2!" > /var/www/html/index.html
			
			mkdir -p /var/www/html
			cd /var/www/html
			python3 -m http.server 3000 &
			EOF
}

//create s3 bucket for web app hosting
resource "aws_s3_bucket" "web_app_bucket" {
	bucket_prefix = "web-app-bucket-"  //AWS generates a name like:  web-app-bucket-887278923
	force_destroy = true
}

//enable versioning for the web app s3 bucket
resource "aws_s3_bucket_versioning" "web_app_bucket_versioning" {
	bucket = aws_s3_bucket.web_app_bucket.id
	versioning_configuration {
		status = "Enabled"
	}
}

//enable server-side encryption for the web app s3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "web_app_bucket_encryption" {
	bucket = aws_s3_bucket.web_app_bucket.bucket
	rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}
	}
}

/* set vpc data source to get default vpc,
to create a logically isolated, private virtual network in the cloud 
where you can launch AWS resources, 
giving you complete control over your virtual networking environment */
data "aws_vpc" "default_vpc" {
	default = true
}

/* The aws_subnet data source in Terraform is used to retrieve a 
set of subnet IDs for a specific VPC based on applied filters. 
This allows other Terraform resources to dynamically reference existing 
subnets without needing their explicit IDs hardcoded in the configuration */
data "aws_subnets" "default_subnets" {
	filter {
		name   = "vpc-id"
		values = [data.aws_vpc.default_vpc.id]
	}
}

/* Defines a security group without rules */
resource "aws_security_group" "instance" {
	name = "instance-security-group"
}

/* Allows inbound HTTP traffic on port 3000 */
resource "aws_security_group_rule" "allow_http_inbound" {
	type = "ingress"             // type ingress = inbound, egress = outbound
	security_group_id = aws_security_group.instance.id   // Reference the security group created above
	from_port = 3000
	to_port = 3000
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]   // Allow from any IP address cidr means Classless Inter-Domain Routing
}

/* The ARN is the Amazon Resource Name (unique ID) of your Load Balancer. */
resource "aws_lb_listener" "http_listener" {
	load_balancer_arn = aws_lb.load_balancer.arn  //to retrieve ALB ARN
	port = 80
	protocol = "HTTP"

	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = "404"
		}
	}
}

resource "aws_lb_target_group" "lb_instance_target_group" {
	name = "lb-instance-target-group"
	port = 3000
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default_vpc.id

	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 5
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}

//attach EC2 instance 1 to the target group which means to the lb
resource "aws_lb_target_group_attachment" "ec2_instance_1_attachment" {
	target_group_arn = aws_lb_target_group.lb_instance_target_group.arn
	target_id = aws_instance.ec2_instance_1.id
	port = 3000
}

//attach EC2 instance 2 to the target group which means to the lb
resource "aws_lb_target_group_attachment" "ec2_instance_2_attachment" {
	target_group_arn = aws_lb_target_group.lb_instance_target_group.arn
	target_id = aws_instance.ec2_instance_2.id
	port = 3000
}


resource "aws_lb_listener_rule" "lb_listener_rule" {
	listener_arn = aws_lb_listener.http_listener.arn
	priority = 100

	condition {
		path_pattern {
			values = ["*"]  //matches all the paths example: /, /api
		}
	}

	action {      //what the ALB should do when conditions matches
		type = "forward"   //Forward requests to a target group
		target_group_arn = aws_lb_target_group.lb_instance_target_group.arn   //reference the target group created above
	}
}

resource "aws_security_group" "alb_security_group" {  //all sg are same structure
	name = "alb-security-group"
}

//allow inbound HTTP traffic on port 80 to ALB
resource "aws_security_group_rule" "allow_alb_http_inbound" {
	type = "ingress"
	security_group_id = aws_security_group.alb_security_group.id
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}

//allow outbound traffic from ALB to anywhere
resource "aws_security_group_rule" "allow_alb_http_outbound" {
	type = "egress"
	security_group_id = aws_security_group.alb_security_group.id
	from_port = 0
	to_port = 0
	protocol = "-1"   //-1 means all protocols
	cidr_blocks = ["0.0.0.0/0"]
}

//create an application load balancer
resource "aws_lb" "load_balancer" {
	name = "web-app-load-balancer"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default_subnets.ids
	security_groups = [aws_security_group.alb_security_group.id]
}

resource "aws_route53_zone" "primary_zone" {
	name = "elebot.pro"
}

//create an A record in route53 to point to the ALB
resource "aws_route53_record" "web_app_root" {
	zone_id = aws_route53_zone.primary_zone.zone_id
	name = "elebot.pro"
	type = "A"
	alias {
		name = aws_lb.load_balancer.dns_name
		zone_id = aws_lb.load_balancer.zone_id
		evaluate_target_health = true
	}
}

resource "aws_db_instance" "db_instance" {
	allocated_storage = 20
	auto_minor_version_upgrade = true
	storage_type = "standard"
	engine = "postgres"
	engine_version = "12.7"
	instance_class = "db.t2.micro"
	identifier = "mypostdbinstance"
	username = "postgresAdmin"
	password = "Postgres@123"
	skip_final_snapshot = true  //this means no snapshot will be taken when the db is deleted
}