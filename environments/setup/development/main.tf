variable "service_name" {}
variable "s3_bucket_terraform_state_id" {}
variable "codecommit_api_repository" {}
variable "codecommit_web_repository" {}

provider "aws" {}

terraform {
  required_version = ">= 0.11.0"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

module "s3_bucket_build_artifacts" {
  source          = "../../../modules/s3/bucket/build_artifacts"
  resource_prefix = "${local.resource_prefix}"
}

## outputs

output "service_name" {
  value = "${var.service_name}"
}

output "codecommit_api_repository" {
  value = "${var.codecommit_api_repository}"
}

output "codecommit_web_repository" {
  value = "${var.codecommit_web_repository}"
}

output "s3_bucket_artifacts_id" {
  value = "${module.s3_bucket_build_artifacts.id}"
}

output "s3_bucket_artifacts_arn" {
  value = "${module.s3_bucket_build_artifacts.arn}"
}
