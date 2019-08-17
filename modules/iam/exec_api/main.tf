variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}
variable "cloudformation_api_stack" {}

## role

data "template_file" "iam_assume_role_policy_exec_api" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "exec_api" {
  name               = "${var.resource_prefix}-api-lambda-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_exec_api.rendered}"
}

## role policy

data "template_file" "iam_policy_exec_api" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    aws_account_id           = "${var.aws_account_id}"
    resource_prefix          = "${var.resource_prefix}"
    cloudformation_api_stack = "${var.cloudformation_api_stack}"
  }
}

resource "aws_iam_role_policy" "exec_api" {
  name   = "${var.resource_prefix}-api-lambda-policy-01"
  role   = "${aws_iam_role.exec_api.id}"
  policy = "${data.template_file.iam_policy_exec_api.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.exec_api.arn}"
}
