# Management VPC
resource "aws_vpc" "mgmt_vpc" {
  cidr_block           = var.mgmt_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-mgmt-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "mgmt_igw" {
  vpc_id = aws_vpc.mgmt_vpc.id

  tags = {
    Name        = "${var.environment}-mgmt-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "mgmt_public_subnet_1a" {
  vpc_id                  = aws_vpc.mgmt_vpc.id
  cidr_block              = cidrsubnet(var.mgmt_vpc_cidr, 8, 1)
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-mgmt-public-1a"
    Environment = var.environment
  }
}

resource "aws_route_table" "mgmt_public_rt" {
  vpc_id = aws_vpc.mgmt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mgmt_igw.id
  }

  tags = {
    Name = "${var.environment}-mgmt-public-rt"
  }
}

resource "aws_route_table_association" "mgmt_public_assoc_1a" {
  subnet_id      = aws_subnet.mgmt_public_subnet_1a.id
  route_table_id = aws_route_table.mgmt_public_rt.id
}

# Production VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block           = var.prod_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-prod-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name        = "${var.environment}-prod-igw"
    Environment = var.environment
  }
}

# Public Subnets (For NLB and NAT Gateways)
resource "aws_subnet" "prod_public_subnet_1a" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = cidrsubnet(var.prod_vpc_cidr, 8, 1)
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-prod-public-1a"
  }
}

resource "aws_subnet" "prod_public_subnet_1b" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = cidrsubnet(var.prod_vpc_cidr, 8, 2)
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-prod-public-1b"
  }
}

# NAT Gateways
resource "aws_eip" "nat_1a" {
  domain = "vpc"
}

resource "aws_eip" "nat_1b" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.prod_public_subnet_1a.id
  depends_on    = [aws_internet_gateway.prod_igw]
  tags = {
    Name = "${var.environment}-prod-nat-1a"
  }
}

resource "aws_nat_gateway" "nat_1b" {
  allocation_id = aws_eip.nat_1b.id
  subnet_id     = aws_subnet.prod_public_subnet_1b.id
  depends_on    = [aws_internet_gateway.prod_igw]
  tags = {
    Name = "${var.environment}-prod-nat-1b"
  }
}

# Public Route Table
resource "aws_route_table" "prod_public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }

  tags = {
    Name = "${var.environment}-prod-public-rt"
  }
}

resource "aws_route_table_association" "prod_public_assoc_1a" {
  subnet_id      = aws_subnet.prod_public_subnet_1a.id
  route_table_id = aws_route_table.prod_public_rt.id
}

resource "aws_route_table_association" "prod_public_assoc_1b" {
  subnet_id      = aws_subnet.prod_public_subnet_1b.id
  route_table_id = aws_route_table.prod_public_rt.id
}

# Private Subnets (App & Nginx Tier)
resource "aws_subnet" "prod_private_app_1a" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 8, 11)
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.environment}-prod-private-app-1a"
  }
}

resource "aws_subnet" "prod_private_app_1b" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 8, 12)
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.environment}-prod-private-app-1b"
  }
}

# Private Route Tables
resource "aws_route_table" "prod_private_rt_1a" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "${var.environment}-prod-private-rt-1a"
  }
}

resource "aws_route_table" "prod_private_rt_1b" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1b.id
  }

  tags = {
    Name = "${var.environment}-prod-private-rt-1b"
  }
}

resource "aws_route_table_association" "prod_private_app_assoc_1a" {
  subnet_id      = aws_subnet.prod_private_app_1a.id
  route_table_id = aws_route_table.prod_private_rt_1a.id
}

resource "aws_route_table_association" "prod_private_app_assoc_1b" {
  subnet_id      = aws_subnet.prod_private_app_1b.id
  route_table_id = aws_route_table.prod_private_rt_1b.id
}

# Database Subnets
resource "aws_subnet" "prod_private_db_1a" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 8, 21)
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.environment}-prod-private-db-1a"
  }
}

resource "aws_subnet" "prod_private_db_1b" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 8, 22)
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.environment}-prod-private-db-1b"
  }
}

resource "aws_route_table_association" "prod_private_db_assoc_1a" {
  subnet_id      = aws_subnet.prod_private_db_1a.id
  route_table_id = aws_route_table.prod_private_rt_1a.id
}

resource "aws_route_table_association" "prod_private_db_assoc_1b" {
  subnet_id      = aws_subnet.prod_private_db_1b.id
  route_table_id = aws_route_table.prod_private_rt_1b.id
}
