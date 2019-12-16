variable "resource_prefix" {}
variable "logging_bucket_id" {}

resource "aws_s3_bucket" "cloudfront_log_web" {
  bucket = "${var.resource_prefix}-cloudfront-logs-web-01"
  acl    = "private"

  logging {
    target_bucket = "${var.logging_bucket_id}"
    target_prefix = "cloudfront-logs-web-01"
  }
}

## outputs

output "id" {
  value = "${aws_s3_bucket.cloudfront_log_web.id}"
}

output "bucket_domain_name" {
  value = "${aws_s3_bucket.cloudfront_log_web.bucket_domain_name}"
}
