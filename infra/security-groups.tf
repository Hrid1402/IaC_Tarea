resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security Group para funciones Lambda"
  vpc_id      = aws_vpc.example.id

  egress {
    description = "Permitir trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-lambda-sg"
    Environment = local.environment
  }
}

resource "aws_security_group" "sqs_endpoint" {
  name        = "${local.name_prefix}-sqs-endpoint-sg"
  description = "Permitir HTTPS desde las funciones Lambda hacia el endpoint de SQS"
  vpc_id      = aws_vpc.example.id

  ingress {
    description     = "HTTPS desde Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }
  egress {
    description = "Permitir trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${local.name_prefix}-sqs-endpoint-sg"
    Environment = local.environment
  }
}