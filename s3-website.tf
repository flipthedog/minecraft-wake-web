// provision an S3 bucket for static website hosting

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.public_bucket_name
}

resource "aws_s3_bucket_website_configuration" "my_bucket_website" {
  bucket = aws_s3_bucket.my_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket_pab" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.my_bucket_pab]
}

resource "local_file" "index_html" {
  content = templatefile("${path.module}/index.html.tpl", {
    api_url = "https://${aws_api_gateway_rest_api.minecraft_api.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/start"
    api_key = aws_api_gateway_api_key.minecraft_key.value
  })
  filename = "${path.module}/index.html"
}

# Upload the generated index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.my_bucket.id
  key          = "index.html"
  source       = local_file.index_html.filename
  content_type = "text/html"
  etag         = local_file.index_html.content_md5
}

# Output the website URL
output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.my_bucket_website.website_endpoint}"
}
