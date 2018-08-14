variable "resource_prefix" {}
variable "iam_role_build_arn" {}
variable "codecommit_repository" {}
variable "s3_bucket_terraform_state_id" {}
variable "s3_bucket_source_id" {}

resource "aws_codebuild_project" "service_staging" {
  name = "${var.resource_prefix}-staging-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "buildspec_staging.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/ubuntu-base:14.04"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TF_VAR_s3_bucket_terraform_state_id"
      "value" = "${var.s3_bucket_terraform_state_id}"
    }
  }

  artifacts {
    type      = "S3"
    name      = "staging_results"
    location  = "${var.s3_bucket_source_id}"
  }

  service_role = "${var.iam_role_build_arn}"
}

output "name" {
  value = "${aws_codebuild_project.service_staging.name}"
}
