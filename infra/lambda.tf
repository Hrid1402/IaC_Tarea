# Empaquetar el código de la función de procesamiento Lambda
data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/crop_function.zip"
}

# Empaquetar el código de la función de subida Lambda
data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/function.zip"
}

# Función de subida Lambda
resource "aws_lambda_function" "upload_lambda" {
  filename      = data.archive_file.upload_zip.output_path
  function_name = "${local.name_prefix}-upload-lambda"
  role          = aws_iam_role.upload-lambda-role.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.upload_zip.output_base64sha256
  runtime       = "nodejs20.x"
  memory_size   = 256
  timeout       = 30
  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.image_bucket.id
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_group_ids = [
      aws_security_group.lambda.id
    ]
  }
}

# Función de procesamiento Lambda (Crop)
resource "aws_lambda_function" "crop_lambda" {
  filename      = data.archive_file.crop_zip.output_path
  function_name = "${local.name_prefix}-crop-lambda"
  role          = aws_iam_role.crop-lambda-role.arn
  handler       = "crop.handler"
  code_sha256   = data.archive_file.crop_zip.output_base64sha256
  runtime       = "nodejs20.x"
  memory_size   = 512
  timeout       = 60
  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.image_bucket.id
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_group_ids = [
      aws_security_group.lambda.id
    ]
  }
}

# Asociar SQS con función Lambda
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn        = aws_sqs_queue.main_queue.arn
  function_name           = aws_lambda_function.crop_lambda.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}
