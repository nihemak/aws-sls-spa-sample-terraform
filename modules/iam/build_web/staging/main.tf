variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}
variable "s3_bucket_web_arn" {}
variable "s3_bucket_source_arn" {}

## role

data "template_file" "iam_assume_role_policy_build_web" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "build_web" {
  name               = "${var.resource_prefix}-codebuild-web-deploy-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_build_web.rendered}"
}

## policy

data "template_file" "iam_policy_build_web" {
  template = "${file("${var.path}/policy.json")}"

  vars {
    aws_account_id       = "${var.aws_account_id}"
    resource_prefix      = "${var.resource_prefix}"
    s3_bucket_web_arn    = "${var.s3_bucket_web_arn}"
    s3_bucket_source_arn = "${var.s3_bucket_source_arn}"
  }
}

resource "aws_iam_role_policy" "build_web" {
  name   = "${var.resource_prefix}-codebuild-web-deploy-policy-01"
  role   = "${aws_iam_role.build_web.id}"
  policy = "${data.template_file.iam_policy_build_web.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.build_web.arn}"
}
