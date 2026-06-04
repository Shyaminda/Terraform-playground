resource "aws_vpc" "primary_vpc" {
  cidr_block           = var.primary_vpc_cidr
  provider             = aws.primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "primary-vpc-${var.primary_region}"
  }
}

resource "aws_vpc" "secondary_vpc" {
  cidr_block           = var.secondary_vpc_cidr
  provider             = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "secondary-vpc-${var.secondary_region}"
  }
}

resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.primary_vpc_cidr
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true //making instances public

  tags = {
    Name        = "primary-Subnet-${var.primary_region}"
    Environment = "dev"
  }
}

resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.secondary_vpc_cidr
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true //making instances public

  tags = {
    Name        = "primary-Subnet-${var.secondary_region}"
    Environment = "dev"
  }
}

resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  tags = {
    Name        = "primary-igw-${var.primary_region}"
    Environment = "dev"
  }
}

resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  tags = {
    Name        = "secondary-igw-${var.secondary_region}"
    Environment = "dev"
  }
}

resource "aws_route_table" "primary_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name        = "primary-rt"
    Environment = "dev"
  }
}

resource "aws_route_table" "secondary_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name        = "secondary-rt"
    Environment = "dev"
  }
}

resource "aws_route_table_association" "primary_rta" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

resource "aws_route_table_association" "secondary_rta" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  peer_region = var.secondary_region
  auto_accept = false

  tags = {
    Name        = "primary-to-secondary-peering"
    Environment = "dev"
  }
}

resource "aws_vpc_peering_connection" "secondary_to_primary" {
  provider    = aws.secondary
  vpc_id      = aws_vpc.secondary_vpc.id
  peer_vpc_id = aws_vpc.primary_vpc.id
  peer_region = var.primary_region
  auto_accept = false

  tags = {
    Name        = "secondary-to-primary-peering"
    Environment = "dev"
  }
}
