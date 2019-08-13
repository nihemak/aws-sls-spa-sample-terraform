variable "resource_prefix" {}
variable "codecommit_repository" {}
variable "iam_role_e2e_arn" {}
variable "base_url" {}

resource "aws_codebuild_project" "e2e" {
  name = "${var.resource_prefix}-e2e-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "e2espec.yml"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "BASE_URL"
      "value" = "${var.base_url}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_e2e_arn}"
}

output "name" {
  value = "${aws_codebuild_project.e2e.name}"
}
