resource "aws_s3_bucket" "image_bucket" {
  bucket = "${local.name_prefix}-images-suffix-37xlwgsswl"
  force_destroy = true
  tags = {
    Name        = "${local.name_prefix}-images"
    Environment = local.environment
  }
}

#SSE

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#Versioning
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.image_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.image_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    id = "rule-uploads"
    filter {
      prefix = "uploads/"
    }
    expiration {
      days = 30
    }
    status = "Enabled"
  }
  rule {
    id = "rule-processed"
    filter {
      prefix = "processed/"
    }
    expiration {
      days = 90
    }
    status = "Enabled"
  }
}


#Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_bucket.id
  
  queue {
    queue_arn     = aws_sqs_queue.main_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
  
  depends_on = [aws_sqs_queue_policy.s3_to_sqs]
}