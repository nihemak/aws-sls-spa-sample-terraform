variable "path" {}
variable "resource_prefix" {}
variable "codepipeline_arn" {}

data "template_file" "iam_assume_role_policy_codecommit_codepipeline_api" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "codecommit_codepipeline_api" {
  name = "${var.resource_prefix}-cwe-api-role-01"

  assume_role_policy = "${data.template_file.iam_assume_role_policy_codecommit_codepipeline_api.rendered}"
}

data "template_file" "codecommit_codepipeline_api" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    codepipeline_arn = "${var.codepipeline_arn}"    
  }
}

resource "aws_iam_role_policy" "codecommit_codepipeline_api" {
  name = "${var.resource_prefix}-cwe-api-policy-01"
  role = "${aws_iam_role.codecommit_codepipeline_api.id}"

  policy = "${data.template_file.codecommit_codepipeline_api.rendered}"
}

output "arn" {
    value = "${aws_iam_role.codecommit_codepipeline_api.arn}"
}
