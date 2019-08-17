variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}
variable "cloudformation_api_stack" {}
variable "s3_bucket_source_arn" {}

## role

data "template_file" "iam_assume_role_policy_build_api" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "build_api" {
  name               = "${var.resource_prefix}-codebuild-sls-deploy-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_build_api.rendered}"
}

## policy

data "template_file" "iam_policy_build_api" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    aws_account_id           = "${var.aws_account_id}"
    resource_prefix          = "${var.resource_prefix}"
    cloudformation_api_stack = "${var.cloudformation_api_stack}"
    s3_bucket_source_arn     = "${var.s3_bucket_source_arn}"
  }
}

resource "aws_iam_role_policy" "build_api" {
  name   = "${var.resource_prefix}-codebuild-sls-deploy-policy-01"
  role   = "${aws_iam_role.build_api.id}"
  policy = "${data.template_file.iam_policy_build_api.rendered}"
}

output "arn" {
  value = "${aws_iam_role.build_api.arn}"
}
