resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
}

resource "aws_s3_bucket" "static" {
  bucket        = "${var.prefix}-static-files-${lower(random_string.bucket_suffix.result)}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.static.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_ownership_controls" "static" {
  bucket = aws_s3_bucket.static.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.static,
    aws_s3_bucket_public_access_block.static,
  ]

  bucket = aws_s3_bucket.static.id
  acl    = "public-read"
}
