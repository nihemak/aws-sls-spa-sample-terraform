variable "path" {}
variable "resource_prefix" {}
variable "aws_account_id" {}
variable "s3_bucket_arn" {}
variable "cloudformation_tool_stack" {}

## role

data "template_file" "iam_assume_role_policy_apigw_firehose_to_s3" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "apigw_firehose_to_s3" {
  name               = "${var.resource_prefix}-apigw-firehose-to-s3-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_apigw_firehose_to_s3.rendered}"
}

## role policy

data "template_file" "iam_policy_apigw_firehose_to_s3" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    s3_bucket_arn             = "${var.s3_bucket_arn}"
    aws_account_id            = "${var.aws_account_id}"
    cloudformation_tool_stack = "${var.cloudformation_tool_stack}"
  }
}

resource "aws_iam_role_policy" "apigw_firehose_to_s3" {
  name   = "${var.resource_prefix}-apigw-firehose-to-s3-policy-01"
  role   = "${aws_iam_role.apigw_firehose_to_s3.id}"
  policy = "${data.template_file.iam_policy_apigw_firehose_to_s3.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.apigw_firehose_to_s3.arn}"
}
