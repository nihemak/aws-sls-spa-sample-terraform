variable "resource_prefix" {}
variable "iam_role_build_web_arn" {}
variable "s3_bucket_web_id" {}
variable "codecommit_repository" {}

resource "aws_codebuild_project" "destroy_web" {
  name = "${var.resource_prefix}-destroy-web-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "buildspec_destroy.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "DEPLOY_BUCKET"
      value = "${var.s3_bucket_web_id}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_web_arn}"
}

output "name" {
  value = "${aws_codebuild_project.destroy_web.name}"
}
