variable "resource_prefix" {}
variable "iam_role_build_web_arn" {}
variable "s3_bucket_web_id" {}
variable "stage" {}
variable "cognito_pool_id" {}
variable "cognito_pool_client_id" {}
variable "api_base_url" {}
variable "codecommit_repository" {}

resource "aws_codebuild_project" "web" {
  name = "${var.resource_prefix}-web-codebuild-01"

  source {
    type     = "CODECOMMIT"
    location = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.codecommit_repository}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "STAGE_ENV"
      value = "${var.stage}"
    }

    environment_variable {
      name  = "DEPLOY_BUCKET"
      value = "${var.s3_bucket_web_id}"
    }

    environment_variable {
      name  = "USER_POOL_ID"
      value = "${var.cognito_pool_id}"
    }

    environment_variable {
      name  = "USER_POOL_CLIENT_ID"
      value = "${var.cognito_pool_client_id}"
    }

    environment_variable {
      name  = "API_BASE_URL"
      value = "${var.api_base_url}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_web_arn}"
}

output "name" {
  value = "${aws_codebuild_project.web.name}"
}
