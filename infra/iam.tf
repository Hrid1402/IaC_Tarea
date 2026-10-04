data "aws_iam_policy_document" "upload-lambda" {
  statement {
    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_policy" "upload-lambda-s3-policy" {
  name   = "upload-lambda-s3-policy"
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
  name               = "upload-lambda-role"
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