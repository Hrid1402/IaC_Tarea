#Upload lambda
data "aws_iam_policy_document" "upload-lambda" {
  statement {
    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.image_bucket.arn}/uploads/*"]
  }
}

resource "aws_iam_policy" "upload-lambda-s3-policy" {
  name   = "${local.name_prefix}-upload-lambda-s3-policy"
  policy = data.aws_iam_policy_document.upload-lambda.json
}



data "aws_iam_policy_document" "upload-lambda-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "upload-lambda-role" {
  name               = "${local.name_prefix}-upload-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.upload-lambda-role.json
}


resource "aws_iam_role_policy_attachment" "upload_s3_attach" {
  role       = aws_iam_role.upload-lambda-role.name
  policy_arn = aws_iam_policy.upload-lambda-s3-policy.arn
}


resource "aws_iam_role_policy_attachment" "upload_basic_execution" {
  role       = aws_iam_role.upload-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc_access" {
  role       = aws_iam_role.upload-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
#Crop lambda
data "aws_iam_policy_document" "crop-lambda" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = ["${aws_s3_bucket.image_bucket.arn}/uploads/*"]
  }
  statement {
    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.image_bucket.arn}/processed/*"]
  }

  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]

    resources = [aws_sqs_queue.main_queue.arn]
  }
}

resource "aws_iam_policy" "crop-lambda-s3-policy" {
  name   = "${local.name_prefix}-crop-lambda-s3-policy"
  policy = data.aws_iam_policy_document.crop-lambda.json
}



data "aws_iam_policy_document" "crop-lambda-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "crop-lambda-role" {
  name               = "${local.name_prefix}-crop-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.crop-lambda-role.json
}


resource "aws_iam_role_policy_attachment" "crop_s3_attach" {
  role       = aws_iam_role.crop-lambda-role.name
  policy_arn = aws_iam_policy.crop-lambda-s3-policy.arn
}


resource "aws_iam_role_policy_attachment" "crop_basic_execution" {
  role       = aws_iam_role.crop-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_access" {
  role       = aws_iam_role.crop-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

