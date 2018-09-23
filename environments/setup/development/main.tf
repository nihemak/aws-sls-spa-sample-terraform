variable "service_name" {}
variable "s3_bucket_terraform_state_id" {}
variable "codecommit_infra_repository" {}
variable "codecommit_api_repository" {}
variable "codecommit_web_repository" {}
variable "codecommit_api_branch" {}
variable "codecommit_web_branch" {}

provider "aws" {}

terraform {
  required_version = ">= 0.11.0"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  resource_prefix = "${var.service_name}-setup"
}

module "s3_bucket_build_artifacts" {
  source          = "../../../modules/s3/bucket/build_artifacts"
  resource_prefix = "${local.resource_prefix}"
}

module "iam_role_build_service" {
  source          = "../../../modules/iam/build_service"
  path            = "../../../modules/iam/build_service"
  resource_prefix = "${local.resource_prefix}"
}

module "codebuild_destroy" {
  source                       = "../../../modules/codebuild/destroy_service/development"
  codecommit_repository        = "${var.codecommit_infra_repository}"
  resource_prefix              = "${local.resource_prefix}"
  iam_role_build_arn           = "${module.iam_role_build_service.arn}"
  s3_bucket_terraform_state_id = "${var.s3_bucket_terraform_state_id}"
  codecommit_api_branch        = "${var.codecommit_api_branch}"
  codecommit_web_branch        = "${var.codecommit_web_branch}"
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

output "codebuild_destroy_name" {
  value = "${module.codebuild_destroy.name}"
}
