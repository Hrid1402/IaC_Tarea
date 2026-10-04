# Rol IAM para ejecución de Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        effect = "Allow"

        principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "lambda_exec" {
    name               = "lambda_execution_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Empaquetar el código de la función de procesamiento Lambda
data "archive_file" "crop_zip" {
    type        = "zip"
    source_file = "${path.module}/lambda/crop.js"
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
    function_name = "upload-lambda"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "index.handler"
    code_sha256   = data.archive_file.upload_zip.output_base64sha256
    runtime       = "nodejs20.x"
    memory_size = 256
    timeout     = 30
    environment {
        variables = {
        S3_BUCKET      = aws_s3_bucket.image_bucket.id
        UPLOAD_PREFIX  = "uploads/"
        }
    }
}

# Función de procesamiento Lambda (Crop)
resource "aws_lambda_function" "crop_lambda" {
    filename      = data.archive_file.crop_zip.output_path
    function_name = "crop-lambda"
    role          = aws_iam_role.lambda_exec.arn
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
}

# Adjuntar la política básica de ejecución (permite escribir logs en CloudWatch)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Adjuntar una política que permita acceso a S3 (para que pueda subir la imagen)
resource "aws_iam_role_policy_attachment" "lambda_s3" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}