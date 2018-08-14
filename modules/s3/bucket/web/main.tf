variable "resource_prefix" {}
variable "logging_bucket_id" {}

resource "aws_s3_bucket" "web" {
  bucket        = "${var.resource_prefix}-web-01"
  acl           = "private"
  force_destroy = true

  logging {
    target_bucket = "${var.logging_bucket_id}"
    target_prefix = "web"
  }
}

output "id" {
  value = "${aws_s3_bucket.web.id}"
}

output "arn" {
  value = "${aws_s3_bucket.web.arn}"
}

output "domain_name" {
  value = "${aws_s3_bucket.web.bucket_domain_name}"
}
