variable "path" {}
variable "resource_prefix" {}

## role

data "template_file" "iam_assume_role_policy_e2e" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "e2e" {
  name               = "${var.resource_prefix}-codebuild-e2e-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_e2e.rendered}"
}

resource "aws_iam_policy_attachment" "e2e" {
  name       = "${var.resource_prefix}-codebuild-e2e-role-attachment-01"
  roles      = ["${aws_iam_role.e2e.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "arn" {
  value = "${aws_iam_role.e2e.arn}"
}
