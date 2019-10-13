variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}
variable "cloudformation_tool_stack" {}

## role

data "template_file" "iam_assume_role_policy_exec_tool" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "exec_tool" {
  name               = "${var.resource_prefix}-tool-lambda-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_exec_tool.rendered}"
}

## role policy

data "template_file" "iam_policy_exec_tool" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    aws_account_id            = "${var.aws_account_id}"
    cloudformation_tool_stack = "${var.cloudformation_tool_stack}"
  }
}

resource "aws_iam_role_policy" "exec_tool" {
  name   = "${var.resource_prefix}-tool-lambda-policy-01"
  role   = "${aws_iam_role.exec_tool.id}"
  policy = "${data.template_file.iam_policy_exec_tool.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.exec_tool.arn}"
}
