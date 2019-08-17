variable "s3_bucket_terraform_state_id" {}
variable "tfstate_setup_key" {}
variable "tfstate_service_api_production_key" {}
variable "tfstate_service_api_staging_key" {}
variable "tfstate_service_web_production_key" {}
variable "tfstate_service_web_staging_key" {}

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

data "terraform_remote_state" "setup" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_setup_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_api_production" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_api_production_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_api_staging" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_api_staging_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_web_production" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_web_production_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_web_staging" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_web_staging_key}"
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  resource_prefix = "${data.terraform_remote_state.setup.outputs.resource_prefix}"
}

## api

module "codepipeline_api" {
  source                      = "../../../modules/codepipeline/api"
  resource_prefix             = "${local.resource_prefix}"
  s3_bucket_artifact_store_id = "${data.terraform_remote_state.setup.outputs.s3_bucket_artifacts_id}"
  codecommit_repository       = "${data.terraform_remote_state.setup.outputs.codecommit_api_repository}"
  iam_role_pipeline_build_arn = "${data.terraform_remote_state.setup.outputs.iam_role_pipeline_build_arn}"
  codebuild_name_test         = "${data.terraform_remote_state.setup.outputs.codebuild_test_api_name}"
  codebuild_name_staging      = "${data.terraform_remote_state.service_api_staging.outputs.codebuild_api_name}"
  codebuild_name_production   = "${data.terraform_remote_state.service_api_production.outputs.codebuild_api_name}"
  approval_sns_topic_arn      = "${data.terraform_remote_state.setup.outputs.approval_sns_topic_arn}"
}

module "cloudwatch_codepipeline_api" {
  source                = "../../../modules/cloudwatch_event/api"
  path                  = "../../../modules/cloudwatch_event/api"
  resource_prefix       = "${local.resource_prefix}"
  aws_account_id        = "${data.aws_caller_identity.current.account_id}"
  codecommit_repository = "${data.terraform_remote_state.setup.outputs.codecommit_api_repository}"
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
  s3_bucket_artifact_store_id = "${data.terraform_remote_state.setup.outputs.s3_bucket_artifacts_id}"
  codecommit_repository       = "${data.terraform_remote_state.setup.outputs.codecommit_web_repository}"
  iam_role_pipeline_build_arn = "${data.terraform_remote_state.setup.outputs.iam_role_pipeline_build_arn}"
  codebuild_name_test         = "${data.terraform_remote_state.setup.outputs.codebuild_test_web_name}"
  codebuild_name_staging      = "${data.terraform_remote_state.service_web_staging.outputs.codebuild_web_name}"
  codebuild_name_staging_e2e  = "${data.terraform_remote_state.service_web_staging.outputs.codebuild_e2e_name}"
  codebuild_name_production   = "${data.terraform_remote_state.service_web_production.outputs.codebuild_web_name}"
  approval_sns_topic_arn      = "${data.terraform_remote_state.setup.outputs.approval_sns_topic_arn}"
}

module "cloudwatch_codepipeline_web" {
  source                = "../../../modules/cloudwatch_event/web"
  path                  = "../../../modules/cloudwatch_event/web"
  resource_prefix       = "${local.resource_prefix}"
  aws_account_id        = "${data.aws_caller_identity.current.account_id}"
  codecommit_repository = "${data.terraform_remote_state.setup.outputs.codecommit_web_repository}"
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
