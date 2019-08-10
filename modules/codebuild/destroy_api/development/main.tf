variable "resource_prefix" {}
variable "stage" {}
variable "cognito_pool_arn" {}
variable "iam_role_exec_api_arn" {}
variable "cors" {}
variable "s3_bucket_build_api_id" {}
variable "iam_role_build_api_arn" {}
variable "codecommit_repository" {}
variable "service_name" {}

resource "aws_codebuild_project" "destroy_api" {
  name = "${var.resource_prefix}-destroy-api-codebuild-01"

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
      "name"  = "STAGE_ENV"
      "value" = "${var.stage}"
    }

    environment_variable {
      "name"  = "LAMBDA_ROLE"
      "value" = "${var.iam_role_exec_api_arn}"
    }

    environment_variable {
      "name"  = "CORS"
      "value" = "${var.cors}"
    }

   environment_variable {
      "name"  = "TZ"
      "value" = "Asia/Tokyo"
    }

    environment_variable {
      "name"  = "COGNITO_POOL_ARN"
      "value" = "${var.cognito_pool_arn}"
    }

    environment_variable {
      "name"  = "DYNAMO_PREFIX"
      "value" = "${var.resource_prefix}"
    }

    environment_variable {
      "name"  = "DEPLOY_BUCKET"
      "value" = "${var.s3_bucket_build_api_id}"
    }

    environment_variable {
      "name"  = "SERVICE_NAME"
      "value" = "${var.service_name}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_api_arn}"
}

output "name" {
  value = "${aws_codebuild_project.destroy_api.name}"
}
