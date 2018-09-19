variable "service_name" {}
variable "s3_bucket_terraform_state_id" {}
variable "codecommit_infra_repository" {}
variable "codecommit_api_repository" {}
variable "codecommit_web_repository" {}
variable "approval_sns_topic_arn" {}

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

module "codebuild_staging" {
  source                       = "../../../modules/codebuild/service/staging"
  codecommit_repository        = "${var.codecommit_infra_repository}"
  s3_bucket_source_id          = "${module.s3_bucket_build_artifacts.id}"
  resource_prefix              = "${local.resource_prefix}"
  iam_role_build_arn           = "${module.iam_role_build_service.arn}"
  s3_bucket_terraform_state_id = "${var.s3_bucket_terraform_state_id}"
}

module "codebuild_production" {
  source                       = "../../../modules/codebuild/service/production"
  s3_bucket_source_arn         = "${module.s3_bucket_build_artifacts.arn}"
  resource_prefix              = "${local.resource_prefix}"
  iam_role_build_arn           = "${module.iam_role_build_service.arn}"
  s3_bucket_terraform_state_id = "${var.s3_bucket_terraform_state_id}"
}

module "iam_role_pipeline_build" {
  source          = "../../../modules/iam/pipeline_build"
  path            = "../../../modules/iam/pipeline_build"
  resource_prefix = "${local.resource_prefix}"
}

module "codepipeline_service" {
  source                      = "../../../modules/codepipeline/service"
  resource_prefix             = "${local.resource_prefix}"
  s3_bucket_artifact_store_id = "${module.s3_bucket_build_artifacts.id}"
  codecommit_repository       = "${var.codecommit_infra_repository}"
  iam_role_pipeline_build_arn = "${module.iam_role_pipeline_build.arn}"
  codebuild_name_staging      = "${module.codebuild_staging.name}"
  codebuild_name_production   = "${module.codebuild_production.name}"
  approval_sns_topic_arn      = "${var.approval_sns_topic_arn}"
}

module "cloudwatch_codepipeline_service" {
  source                = "../../../modules/cloudwatch_event/service"
  path                  = "../../../modules/cloudwatch_event/service"
  resource_prefix       = "${local.resource_prefix}"
  aws_account_id        = "${data.aws_caller_identity.current.account_id}"
  codecommit_repository = "${var.codecommit_infra_repository}"
}

module "iam_role_codecommit_codepipeline_service" {
  source           = "../../../modules/iam/codecommit_codepipeline_service"
  path             = "../../../modules/iam/codecommit_codepipeline_service"
  resource_prefix  = "${local.resource_prefix}"
  codepipeline_arn = "${module.codepipeline_service.arn}"
}

resource "aws_cloudwatch_event_target" "codepipeline_service" {
  target_id = "${local.resource_prefix}-codepipeline-service-rule-01"
  arn       = "${module.codepipeline_service.arn}"
  rule      = "${module.cloudwatch_codepipeline_service.name}"
  role_arn  = "${module.iam_role_codecommit_codepipeline_service.arn}"
}

## outputs

output "service_name" {
  value = "${var.service_name}"
}

output "resource_prefix" {
  value = "${local.resource_prefix}"
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

output "iam_role_pipeline_build_arn" {
  value = "${module.iam_role_pipeline_build.arn}"
}

output "codepipeline_service_name" {
  value = "${module.codepipeline_service.id}"
}

output "approval_sns_topic_arn" {
  value = "${var.approval_sns_topic_arn}"
}
