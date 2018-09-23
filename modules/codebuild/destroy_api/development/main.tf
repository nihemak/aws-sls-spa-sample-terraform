variable "resource_prefix" {}
variable "iam_role_build_api_arn" {}
variable "codecommit_repository" {}

resource "aws_codebuild_project" "destroy_api" {
  name = "${var.resource_prefix}-destroy-api-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "buildspec_destroy.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:8.11.0"
    type         = "LINUX_CONTAINER"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_api_arn}"
}

output "name" {
  value = "${aws_codebuild_project.destroy_api.name}"
}
