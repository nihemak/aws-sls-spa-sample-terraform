variable "resource_prefix" {}
variable "s3_bucket_audit_log_domain_name" {}
variable "s3_bucket_web_id" {}
variable "s3_bucket_web_domain_name" {}
variable "waf_acl_id" {}

resource "aws_cloudfront_origin_access_identity" "web" {
  comment = "access-identity-${var.s3_bucket_web_domain_name}"
}

resource "aws_cloudfront_distribution" "web" {
  origin {
    domain_name = "${var.s3_bucket_web_domain_name}"
    origin_id   = "S3-${var.s3_bucket_web_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  comment             = "${var.resource_prefix}-web"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${var.s3_bucket_audit_log_domain_name}"
    prefix          = "${var.resource_prefix}-web"
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "S3-${var.s3_bucket_web_id}"

    viewer_protocol_policy = "https-only"
    min_ttl                = 1
    default_ttl            = 1
    max_ttl                = 1

    compress = false

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_200"

  tags {
    billing = "${var.resource_prefix}-web"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = "${var.waf_acl_id}"
}

output "origin_access_identity" {
  value = "${aws_cloudfront_origin_access_identity.web.id}"
}

output "domain_name" {
  value = "${aws_cloudfront_distribution.web.domain_name}"
}
