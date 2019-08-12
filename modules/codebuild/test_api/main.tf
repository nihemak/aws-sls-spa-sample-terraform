variable "resource_prefix" {}
variable "codecommit_repository" {}
variable "iam_role_test_api_arn" {}

resource "aws_codebuild_project" "test_api" {
  name = "${var.resource_prefix}-test-api-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "testspec.yml"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_test_api_arn}"
}

output "name" {
  value = "${aws_codebuild_project.test_api.name}"
}
