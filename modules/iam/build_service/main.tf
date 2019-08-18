variable "path" {}
variable "resource_prefix" {}

## role

data "template_file" "iam_assume_role_policy_build_service" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "build_service" {
  name               = "${var.resource_prefix}-codebuild-service-deploy-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_build_service.rendered}"
}

resource "aws_iam_role_policy_attachment" "build_service" {
  role       = "${aws_iam_role.build_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "arn" {
  value = "${aws_iam_role.build_service.arn}"
}
