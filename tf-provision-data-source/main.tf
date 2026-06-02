# data source to fetch existing VPC details
data "aws_vpc" "shared_vpc" {
	filter {
		name = "tag:Name"
		values = ["shared-network-vpc"]
	}
}

# data source to fetch existing subnet details
data "aws_subnet" "shared_subnet" {
	filter {
		name = "tag:Name"
		values = ["shared-primary-subnet"]
	}

	vpc_id = data.aws_vpc.shared_vpc.id
}

data "aws_ami" "amazon_linux_2" {
	most_recent = true
	owners = ["amazon"]

	filter {
		name = "name"
		values = ["amzn2-ami-hvm-*-x86_64-gp2"]
	}

	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
}

resource "aws_instance" "demo_instance" {
	ami = data.aws_ami.amazon_linux_2.id
	instance_type = "t2.micro"
	subnet_id = data.aws_subnet.shared_subnet.id
}