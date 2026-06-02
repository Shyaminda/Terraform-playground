resource "aws_s3_bucket" "static_web_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_web_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "demo-oac"
  description                       = "demo Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cf_access" {
  bucket = aws_s3_bucket.static_web_bucket.id
  depends_on = [aws_public_access_block.public_access_block]

  policy = jsonencode( //generated from https://awspolicygen.s3.amazonaws.com/policygen.html
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowCloudFront",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "cloudfront.amazonaws.com"
          },
          "Action" : [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource" : "${aws_s3_bucket.static_web_bucket.arn}/*",
          "Condition" : {
            "StringEquals" : {
              "aws:SourceArn" : "aws_cloudfront_distribution.s3_distribution.arn"
            }
          }
        }
      ]
    }
  )
}
