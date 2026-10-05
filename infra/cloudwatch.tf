resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-upload-lambda"
  retention_in_days = 14

  tags = {
    Name        = "${local.name_prefix}-upload-lambda-logs"
    Environment = local.environment
  }
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-crop-lambda"
  retention_in_days = 14

  tags = {
    Name        = "${local.name_prefix}-crop-lambda-logs"
    Environment = local.environment
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = 14

  tags = {
    Name        = "${local.name_prefix}-api-logs"
    Environment = local.environment
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name        = "${local.name_prefix}-alerts"
    Environment = local.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = local.environment == "dev" ? "dlq-messages-alarm" : "dlq-messages-alarm-${local.environment}"
  alarm_description   = "Alerta cuando la DLQ contiene uno o mas mensajes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq_queue.name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name        = "${local.name_prefix}-dlq-messages-alarm"
    Environment = local.environment
  }
}