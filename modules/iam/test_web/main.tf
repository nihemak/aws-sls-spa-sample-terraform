variable "path" {}
variable "resource_prefix" {}

## role

data "template_file" "iam_assume_role_policy_test_web" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "test_web" {
  name               = "${var.resource_prefix}-codebuild-test-web-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_test_web.rendered}"
}

resource "aws_iam_policy_attachment" "test_web" {
  name       = "${var.resource_prefix}-codebuild-test-web-role-attachment-01"
  roles      = ["${aws_iam_role.test_web.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "arn" {
  value = "${aws_iam_role.test_web.arn}"
}
