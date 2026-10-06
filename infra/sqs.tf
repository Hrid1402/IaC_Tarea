resource "aws_sqs_queue" "dlq_queue" {
  name                      = "${local.name_prefix}-images-dlq"
  message_retention_seconds = 1209600
  tags = {
    Environment = local.environment
  }
}

resource "aws_sqs_queue" "main_queue" {
  name                       = "${local.name_prefix}-images-queue"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_queue.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = local.environment
  }
}

resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_s3_bucket.image_bucket.arn }
        }
      }
    ]
  })
}