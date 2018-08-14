variable "path" {}
variable "resource_prefix" {}

data "template_file" "iam_assume_role_policy_pipeline_build" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "pipeline_build" {
  name = "${var.resource_prefix}-codepipeline-build-role-01"

  assume_role_policy = "${data.template_file.iam_assume_role_policy_pipeline_build.rendered}"
}

data "template_file" "iam_policy_pipeline_build" {
  template = "${file("${var.path}/policy.json")}"
}

resource "aws_iam_role_policy" "pipeline_build" {
  name = "${var.resource_prefix}-codepipeline-build-policy-01"
  role = "${aws_iam_role.pipeline_build.id}"

  policy = "${data.template_file.iam_policy_pipeline_build.rendered}"
}

output "arn" {
  value = "${aws_iam_role.pipeline_build.arn}"
}
