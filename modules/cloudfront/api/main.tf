variable "resource_prefix" {}
variable "stage" {}
variable "apigw_api_domain_name" {}
variable "s3_bucket_audit_log_domain_name" {}
variable "waf_acl_id" {}

resource "aws_cloudfront_distribution" "api" {
  origin {
    domain_name = "${var.apigw_api_domain_name}"
    origin_id   = "Custom-${var.apigw_api_domain_name}/${var.stage}"
    origin_path = "/${var.stage}"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  comment = "${var.resource_prefix}-api"

  custom_error_response {
    error_code            = 500
    error_caching_min_ttl = 1
  }

  custom_error_response {
    error_code            = 501
    error_caching_min_ttl = 1
  }

  custom_error_response {
    error_code            = 502
    error_caching_min_ttl = 1
  }

  custom_error_response {
    error_code            = 503
    error_caching_min_ttl = 1
  }

  custom_error_response {
    error_code            = 504
    error_caching_min_ttl = 1
  }

  default_cache_behavior {
    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["HEAD", "GET"]

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      cookies {
        forward = "all"
      }
      headers      = ["Authorization", "Origin"]
      query_string = true
    }

    target_origin_id       = "Custom-${var.apigw_api_domain_name}/${var.stage}"
    viewer_protocol_policy = "https-only"
  }

  logging_config {
    bucket = "${var.s3_bucket_audit_log_domain_name}"
    prefix = "${var.stage}-api"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    billing = "${var.resource_prefix}-api-01"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  web_acl_id = "${var.waf_acl_id}"
}

output "domain_name" {
  value = "${aws_cloudfront_distribution.api.domain_name}"
}
