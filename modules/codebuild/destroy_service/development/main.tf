variable "resource_prefix" {}
variable "iam_role_build_arn" {}
variable "codecommit_repository" {}
variable "s3_bucket_terraform_state_id" {}
variable "codecommit_api_branch" {}
variable "codecommit_web_branch" {}

resource "aws_codebuild_project" "destroy_service_development" {
  name = "${var.resource_prefix}-destroy-service-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "buildspec_development_destroy.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/ubuntu-base:14.04"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TF_VAR_s3_bucket_terraform_state_id"
      "value" = "${var.s3_bucket_terraform_state_id}"
    }

    environment_variable {
      "name"  = "codecommit_api_branch"
      "value" = "${var.codecommit_api_branch}"
    }

    environment_variable {
      "name"  = "codecommit_web_branch"
      "value" = "${var.codecommit_web_branch}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_arn}"
}

output "name" {
  value = "${aws_codebuild_project.destroy_service_development.name}"
}
