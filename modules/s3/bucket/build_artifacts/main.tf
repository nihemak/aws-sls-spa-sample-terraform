variable "resource_prefix" {}

resource "aws_s3_bucket" "build_artifacts" {
  bucket = "${var.resource_prefix}-build-artifacts"
  acl    = "private"
}

output "id" {
  value = "${aws_s3_bucket.build_artifacts.id}"
}

output "arn" {
  value = "${aws_s3_bucket.build_artifacts.arn}"
}
