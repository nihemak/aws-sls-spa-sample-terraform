variable "resource_prefix" {}
variable "logging_bucket_id" {}

resource "aws_s3_bucket" "build_api" {
  bucket        = "${var.resource_prefix}-api-slsdeploybucket-02"
  acl           = "private"
  force_destroy = true

  logging {
    target_bucket = "${var.logging_bucket_id}"
    target_prefix = "build-api"
  }
}

output "id" {
  value = "${aws_s3_bucket.build_api.id}"
}
