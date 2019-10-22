variable "resource_prefix" {}
variable "iam_role_build_arn" {}
variable "s3_bucket_source_arn" {}
variable "s3_bucket_terraform_state_id" {}
variable "service_resource_prefix" {}
variable "s3_bucket_audit_log_id" {}

resource "aws_codebuild_project" "service_production" {
  name = "${var.resource_prefix}-production-codebuild-01"

  source {
    type     = "S3"
    location = "${var.s3_bucket_source_arn}/staging_results/infrastructure.zip"
    buildspec = "buildspec_production.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_VAR_s3_bucket_terraform_state_id"
      value = "${var.s3_bucket_terraform_state_id}"
    }

    environment_variable {
      name  = "TF_VAR_resource_prefix"
      value = "${var.service_resource_prefix}"
    }

    environment_variable {
      name  = "TF_VAR_s3_bucket_audit_log_id"
      value = "${var.s3_bucket_audit_log_id}"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = "${var.iam_role_build_arn}"
}

output "name" {
  value = "${aws_codebuild_project.service_production.name}"
}
