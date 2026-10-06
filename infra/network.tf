data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-a"
    Environment = local.environment
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-b"
    Environment = local.environment
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name        = "${local.name_prefix}-private-rt-a"
    Environment = local.environment
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.example.id

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