output "assets_bucket" {
  value       = aws_s3_bucket.assets.bucket
  description = "Private bucket for videos/posters"
}

output "cdn_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "Base URL for streaming"
}

output "site_bucket" {
  value       = aws_s3_bucket.site.bucket
  description = "Public website bucket"
}

output "site_url" {
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
  description = "Open this URL for the demo player"
}
