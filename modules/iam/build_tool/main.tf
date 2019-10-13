variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}
variable "cloudformation_tool_stack" {}

## role

data "template_file" "iam_assume_role_policy_build_tool" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "build_tool" {
  name               = "${var.resource_prefix}-codebuild-tool-deploy-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_build_tool.rendered}"
}

## policy

data "template_file" "iam_policy_build_tool" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    aws_account_id            = "${var.aws_account_id}"
    resource_prefix           = "${var.resource_prefix}"
    cloudformation_tool_stack = "${var.cloudformation_tool_stack}"
  }
}

resource "aws_iam_role_policy" "build_tool" {
  name   = "${var.resource_prefix}-codebuild-sls-deploy-policy-01"
  role   = "${aws_iam_role.build_tool.id}"
  policy = "${data.template_file.iam_policy_build_tool.rendered}"
}

output "arn" {
  value = "${aws_iam_role.build_tool.arn}"
}
