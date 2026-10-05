resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.example.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]

  tags = {
    Name        = "${local.name_prefix}-s3-endpoint"
    Environment = local.environment
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.sqs_endpoint.id
  ]

  tags = {
    Name        = "${local.name_prefix}-sqs-endpoint"
    Environment = local.environment
  }
}