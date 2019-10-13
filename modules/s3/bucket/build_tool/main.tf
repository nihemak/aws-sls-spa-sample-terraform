variable "resource_prefix" {}
variable "logging_bucket_id" {}

resource "aws_s3_bucket" "build_tool" {
  bucket        = "${var.resource_prefix}-tool-slsdeploybucket-02"
  acl           = "private"
  force_destroy = true

  logging {
    target_bucket = "${var.logging_bucket_id}"
    target_prefix = "build-tool"
  }
}

output "id" {
  value = "${aws_s3_bucket.build_tool.id}"
}
