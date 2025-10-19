############################################
# main.tf — Mini Netflix (S3 + CloudFront)
# Index page is embedded (no template file)
############################################

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  suffix        = random_id.suffix.hex
  assets_bucket = "mini-netflix-assets-${local.suffix}"
  site_bucket   = "mini-netflix-site-${local.suffix}"
}

# -------- Private Assets Bucket (videos/poster) --------
resource "aws_s3_bucket" "assets" {
  bucket        = local.assets_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "assets_own" {
  bucket = aws_s3_bucket.assets.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

# -------- CloudFront (OAC) for PRIVATE assets --------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "mini-netflix-oac-${local.suffix}"
  description                       = "OAC for private S3 assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  comment = "mini-netflix assets CDN"

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.assets.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.assets.bucket
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Allow ONLY this CloudFront distribution to read the assets bucket
data "aws_iam_policy_document" "assets_policy" {
  statement {
    sid       = "AllowCloudFrontReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_policy.json
}

# -------- Public Site Bucket (S3 static website) --------
resource "aws_s3_bucket" "site" {
  bucket        = local.site_bucket
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_ownership_controls" "site_own" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

# Public access needed for static website hosting (account-level BlockPublicPolicy must allow policies)
resource "aws_s3_bucket_public_access_block" "site_block" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid       = "PublicRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

# -------- index.html (embedded) — auto-plays demo video --------
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-HTML
    <!doctype html>
    <meta charset="utf-8" />
    <title>Mini Netflix – Demo</title>
    <style>
      body { font-family: system-ui, Arial, sans-serif; margin: 2rem; }
      .wrap { max-width: 920px; margin: auto; }
      video { width: 100%; max-width: 900px; display: block; margin: 1rem 0; }
      .hint { color: #555; font-size: .9rem; }
    </style>

    <div class="wrap">
      <h1>Mini Netflix – HTML5 Player</h1>

      <video controls preload="metadata" poster="https://${aws_cloudfront_distribution.cdn.domain_name}/poster.jpg">
        <source src="https://${aws_cloudfront_distribution.cdn.domain_name}/movies/sample.mp4" type="video/mp4">
        Your browser does not support the video tag.
      </video>

      <p class="hint">
        This demo streams from CloudFront (origin is a private S3 bucket via OAC).
        Replace <code>movies/sample.mp4</code> and <code>poster.jpg</code> in the assets bucket to change the video.
      </p>
    </div>
  HTML
}
