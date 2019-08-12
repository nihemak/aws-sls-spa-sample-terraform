variable "s3_bucket_terraform_state_id" {}
variable "tfstate_setup_key" {}
variable "tfstate_service_api_production_key" {}
variable "tfstate_service_api_staging_key" {}
variable "tfstate_service_web_production_key" {}
variable "tfstate_service_web_staging_key" {}

provider "aws" {}

terraform {
  required_version = ">= 0.11.0"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "setup" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_setup_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_api_production" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_api_production_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_api_staging" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_api_staging_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_web_production" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_web_production_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_web_staging" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_web_staging_key}"
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  resource_prefix = "${data.terraform_remote_state.setup.resource_prefix}"
}

## api

module "codepipeline_api" {
  source                      = "../../../modules/codepipeline/api"
  resource_prefix             = "${local.resource_prefix}"
  s3_bucket_artifact_store_id = "${data.terraform_remote_state.setup.s3_bucket_artifacts_id}"
  codecommit_repository       = "${data.terraform_remote_state.setup.codecommit_api_repository}"
  iam_role_pipeline_build_arn = "${data.terraform_remote_state.setup.iam_role_pipeline_build_arn}"
  codebuild_name_test         = "${data.terraform_remote_state.setup.codebuild_test_api_name}"
  codebuild_name_staging      = "${data.terraform_remote_state.service_api_staging.codebuild_api_name}"
  codebuild_name_production   = "${data.terraform_remote_state.service_api_production.codebuild_api_name}"
  approval_sns_topic_arn      = "${data.terraform_remote_state.setup.approval_sns_topic_arn}"
}

module "cloudwatch_codepipeline_api" {
  source                = "../../../modules/cloudwatch_event/api"
  path                  = "../../../modules/cloudwatch_event/api"
  resource_prefix       = "${local.resource_prefix}"
  aws_account_id        = "${data.aws_caller_identity.current.account_id}"
  codecommit_repository = "${data.terraform_remote_state.setup.codecommit_api_repository}"
}

module "iam_role_codecommit_codepipeline_api" {
  source           = "../../../modules/iam/codecommit_codepipeline_api"
  path             = "../../../modules/iam/codecommit_codepipeline_api"
  resource_prefix  = "${local.resource_prefix}"
  codepipeline_arn = "${module.codepipeline_api.arn}"
}

resource "aws_cloudwatch_event_target" "codepipeline_api" {
  target_id = "${local.resource_prefix}-codepipeline-api-rule-01"
  arn       = "${module.codepipeline_api.arn}"
  rule      = "${module.cloudwatch_codepipeline_api.name}"
  role_arn  = "${module.iam_role_codecommit_codepipeline_api.arn}"
}

## web

module "codepipeline_web" {
  source                      = "../../../modules/codepipeline/web"
  resource_prefix             = "${local.resource_prefix}"
  s3_bucket_artifact_store_id = "${data.terraform_remote_state.setup.s3_bucket_artifacts_id}"
  codecommit_repository       = "${data.terraform_remote_state.setup.codecommit_web_repository}"
  iam_role_pipeline_build_arn = "${data.terraform_remote_state.setup.iam_role_pipeline_build_arn}"
  codebuild_name_test         = "${data.terraform_remote_state.setup.codebuild_test_web_name}"
  codebuild_name_staging      = "${data.terraform_remote_state.service_web_staging.codebuild_web_name}"
  codebuild_name_production   = "${data.terraform_remote_state.service_web_production.codebuild_web_name}"
  approval_sns_topic_arn      = "${data.terraform_remote_state.setup.approval_sns_topic_arn}"
}

module "cloudwatch_codepipeline_web" {
  source                = "../../../modules/cloudwatch_event/web"
  path                  = "../../../modules/cloudwatch_event/web"
  resource_prefix       = "${local.resource_prefix}"
  aws_account_id        = "${data.aws_caller_identity.current.account_id}"
  codecommit_repository = "${data.terraform_remote_state.setup.codecommit_web_repository}"
}

module "iam_role_codecommit_codepipeline_web" {
  source           = "../../../modules/iam/codecommit_codepipeline_web"
  path             = "../../../modules/iam/codecommit_codepipeline_web"
  resource_prefix  = "${local.resource_prefix}"
  codepipeline_arn = "${module.codepipeline_web.arn}"
}

resource "aws_cloudwatch_event_target" "codepipeline_web" {
  target_id = "${local.resource_prefix}-codepipeline-web-rule-01"
  arn       = "${module.codepipeline_web.arn}"
  rule      = "${module.cloudwatch_codepipeline_web.name}"
  role_arn  = "${module.iam_role_codecommit_codepipeline_web.arn}"
}
