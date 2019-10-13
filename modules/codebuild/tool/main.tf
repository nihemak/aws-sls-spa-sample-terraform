variable "resource_prefix" {}
variable "stage" {}
variable "iam_role_exec_tool_arn" {}
variable "s3_bucket_build_tool_id" {}
variable "iam_role_build_tool_arn" {}
variable "codecommit_repository" {}
variable "service_name" {}

resource "aws_codebuild_project" "tool" {
  name = "${var.resource_prefix}-tool-codebuild-01"

  source {
    type      = "CODECOMMIT"
    location  = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
    buildspec = "serverless/buildspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "STAGE_ENV"
      value = "${var.stage}"
    }

    environment_variable {
      name  = "LAMBDA_ROLE"
      value = "${var.iam_role_exec_tool_arn}"
    }

    environment_variable {
      name  = "DEPLOY_BUCKET"
      value = "${var.s3_bucket_build_tool_id}"
    }

    environment_variable {
      name  = "SERVICE_NAME"
      value = "${var.service_name}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_tool_arn}"
}

output "name" {
  value = "${aws_codebuild_project.tool.name}"
}
