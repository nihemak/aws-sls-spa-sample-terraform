variable "service_name" {}
variable "s3_bucket_terraform_state_id" {}
variable "codecommit_infra_repository" {}
variable "codecommit_api_repository" {}
variable "codecommit_web_repository" {}
variable "approval_sns_topic_arn" {}
variable "stage_staging" {}
variable "stage_production" {}

provider "aws" {
  version = ">= 2.24"
}

provider "template" {
  version = ">= 2.1"
}

terraform {
  required_version = ">= 0.12.6"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  resource_prefix            = "${var.service_name}-setup"
  resource_prefix_staging    = "${var.service_name}-${var.stage_staging}"
  resource_prefix_production = "${var.service_name}-${var.stage_production}"
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

module "s3_bucket_audit_log_staging" {
  source          = "../../../modules/s3/bucket/audit_log"
  resource_prefix = "${local.resource_prefix_staging}"
}

module "s3_bucket_audit_log_production" {
  source          = "../../../modules/s3/bucket/audit_log"
  resource_prefix = "${local.resource_prefix_production}"
}

module "codebuild_staging" {
  source                                 = "../../../modules/codebuild/service/staging"
  codecommit_repository                  = "${var.codecommit_infra_repository}"
  s3_bucket_source_id                    = "${module.s3_bucket_build_artifacts.id}"
  resource_prefix                        = "${local.resource_prefix}"
  iam_role_build_arn                     = "${module.iam_role_build_service.arn}"
  s3_bucket_terraform_state_id           = "${var.s3_bucket_terraform_state_id}"
  service_resource_prefix                = "${local.resource_prefix_staging}"
  s3_bucket_audit_log_id                 = "${module.s3_bucket_audit_log_staging.id}"
  s3_bucket_audit_log_bucket_domain_name = "${module.s3_bucket_audit_log_staging.bucket_domain_name}"
}

module "codebuild_production" {
  source                                 = "../../../modules/codebuild/service/production"
  s3_bucket_source_arn                   = "${module.s3_bucket_build_artifacts.arn}"
  resource_prefix                        = "${local.resource_prefix}"
  iam_role_build_arn                     = "${module.iam_role_build_service.arn}"
  s3_bucket_terraform_state_id           = "${var.s3_bucket_terraform_state_id}"
  service_resource_prefix                = "${local.resource_prefix_production}"
  s3_bucket_audit_log_id                 = "${module.s3_bucket_audit_log_production.id}"
  s3_bucket_audit_log_bucket_domain_name = "${module.s3_bucket_audit_log_production.bucket_domain_name}"
}

module "iam_role_test_api" {
  source          = "../../../modules/iam/test_api"
  path            = "../../../modules/iam/test_api"
  resource_prefix = "${local.resource_prefix}"
}

module "codebuild_test_api" {
  source                = "../../../modules/codebuild/test_api"
  resource_prefix       = "${local.resource_prefix}"
  codecommit_repository = "${var.codecommit_api_repository}"
  iam_role_test_api_arn = "${module.iam_role_test_api.arn}"
}

module "iam_role_test_web" {
  source          = "../../../modules/iam/test_web"
  path            = "../../../modules/iam/test_web"
  resource_prefix = "${local.resource_prefix}"
}

module "codebuild_test_web" {
  source                = "../../../modules/codebuild/test_web"
  resource_prefix       = "${local.resource_prefix}"
  codecommit_repository = "${var.codecommit_web_repository}"
  iam_role_test_web_arn = "${module.iam_role_test_web.arn}"
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

output "codecommit_infra_repository" {
  value = "${var.codecommit_infra_repository}"
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

output "codebuild_test_api_name" {
  value = "${module.codebuild_test_api.name}"
}

output "codebuild_test_web_name" {
  value = "${module.codebuild_test_web.name}"
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
