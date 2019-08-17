variable "path" {}
variable "resource_prefix" {}
variable "codepipeline_arn" {}

data "template_file" "iam_assume_role_policy_codecommit_codepipeline_web" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "codecommit_codepipeline_web" {
  name = "${var.resource_prefix}-cwe-web-role-01"

  assume_role_policy = "${data.template_file.iam_assume_role_policy_codecommit_codepipeline_web.rendered}"
}

data "template_file" "codecommit_codepipeline_web" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    codepipeline_arn = "${var.codepipeline_arn}"    
  }
}

resource "aws_iam_role_policy" "codecommit_codepipeline_web" {
  name = "${var.resource_prefix}-cwe-web-policy-01"
  role = "${aws_iam_role.codecommit_codepipeline_web.id}"

  policy = "${data.template_file.codecommit_codepipeline_web.rendered}"
}

output "arn" {
    value = "${aws_iam_role.codecommit_codepipeline_web.arn}"
}
