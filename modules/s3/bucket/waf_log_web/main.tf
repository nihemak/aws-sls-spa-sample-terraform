variable "resource_prefix" {}
variable "logging_bucket_id" {}

resource "aws_s3_bucket" "waf_log_web" {
  bucket = "${var.resource_prefix}-waf-logs-web-01"
  acl    = "private"

  logging {
    target_bucket = "${var.logging_bucket_id}"
    target_prefix = "waf-logs-web-01"
  }
}

## outputs

output "arn" {
  value = "${aws_s3_bucket.waf_log_web.arn}"
}
