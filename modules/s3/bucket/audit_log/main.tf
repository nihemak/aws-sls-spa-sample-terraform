variable "resource_prefix" {}

resource "aws_s3_bucket" "audit_log" {
  bucket = "${var.resource_prefix}-logs"
  acl    = "log-delivery-write"

  logging {
    target_bucket = "${var.resource_prefix}-logs"
    target_prefix = "audit-logs"
  }
}

output "id" {
  value = "${aws_s3_bucket.audit_log.id}"
}
