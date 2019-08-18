variable "path" {}
variable "resource_prefix" {}

## role

data "template_file" "iam_assume_role_policy_test_api" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "test_api" {
  name               = "${var.resource_prefix}-codebuild-test-api-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_test_api.rendered}"
}

resource "aws_iam_role_policy_attachment" "test_api" {
  role       = "${aws_iam_role.test_api.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "arn" {
  value = "${aws_iam_role.test_api.arn}"
}
