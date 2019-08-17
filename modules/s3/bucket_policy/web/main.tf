variable "path" {}
variable "cloudfront_origin_access_identity" {}
variable "s3_bucket_web_id" {}
variable "s3_bucket_web_arn" {}
variable "iam_role_build_web_arn" {}

data "template_file" "s3_bucket_policy_web" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    cloudfront_origin_access_identity = "${var.cloudfront_origin_access_identity}"
    s3_bucket_web_arn                 = "${var.s3_bucket_web_arn}"
    iam_role_build_web_arn            = "${var.iam_role_build_web_arn}"
  }
}

resource "aws_s3_bucket_policy" "web" {
  bucket = "${var.s3_bucket_web_id}"
  policy = "${data.template_file.s3_bucket_policy_web.rendered}"
}
