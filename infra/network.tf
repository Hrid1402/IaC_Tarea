data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Environment = local.environment
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-subnet-a"
    Environment = local.environment
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-subnet-b"
    Environment = local.environment
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-a"
    Environment = local.environment
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-b"
    Environment = local.environment
  }
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-eip-nat-a"
    Environment = local.environment
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-eip-nat-b"
    Environment = local.environment
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name        = "${local.name_prefix}-nat-a"
    Environment = local.environment
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name        = "${local.name_prefix}-nat-b"
    Environment = local.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${local.name_prefix}-public-rt"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name        = "${local.name_prefix}-private-rt-a"
    Environment = local.environment
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name        = "${local.name_prefix}-private-rt-b"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}