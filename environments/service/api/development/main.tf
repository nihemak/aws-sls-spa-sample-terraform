variable "stage" {}
variable "s3_bucket_terraform_state_id" {}
variable "tfstate_setup_key" {}
variable "tfstate_service_base_pre_key" {}

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

data "terraform_remote_state" "setup" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_setup_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_base_pre" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_base_pre_key}"
    region = "ap-northeast-1"
  }
}

locals {
  resource_prefix          = "${data.terraform_remote_state.service_base_pre.outputs.resource_prefix}"
  cloudformation_api_stack = "${data.terraform_remote_state.service_base_pre.outputs.cloudformation_api_stack}"
}

module "iam_role_build_api" {
  source                   = "../../../../modules/iam/build_api"
  path                     = "../../../../modules/iam/build_api"
  aws_account_id           = "${data.aws_caller_identity.current.account_id}"
  resource_prefix          = "${local.resource_prefix}"
  cloudformation_api_stack = "${local.cloudformation_api_stack}"
  s3_bucket_source_arn     = "${data.terraform_remote_state.setup.outputs.s3_bucket_artifacts_arn}"
}

module "s3_bucket_build_api" {
  source            = "../../../../modules/s3/bucket/build_api"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_audit_log_id}"
}

module "codebuild_api" {
  source                 = "../../../../modules/codebuild/api/development"
  codecommit_repository  = "${data.terraform_remote_state.setup.outputs.codecommit_api_repository}"
  iam_role_build_api_arn = "${module.iam_role_build_api.arn}"
  s3_bucket_build_api_id = "${module.s3_bucket_build_api.id}"
  resource_prefix        = "${local.resource_prefix}"
  stage                  = "${var.stage}"
  iam_role_exec_api_arn  = "${data.terraform_remote_state.service_base_pre.outputs.iam_role_exec_api_arn}"
  cognito_pool_id        = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_id}"
  cors                   = "${data.terraform_remote_state.service_base_pre.outputs.web_base_url}"
  service_name           = "${data.terraform_remote_state.setup.outputs.service_name}"
}

module "codebuild_destroy_api" {
  source                 = "../../../../modules/codebuild/destroy_api/development"
  codecommit_repository  = "${data.terraform_remote_state.setup.outputs.codecommit_api_repository}"
  iam_role_build_api_arn = "${module.iam_role_build_api.arn}"
  s3_bucket_build_api_id = "${module.s3_bucket_build_api.id}"
  resource_prefix        = "${local.resource_prefix}"
  stage                  = "${var.stage}"
  iam_role_exec_api_arn  = "${data.terraform_remote_state.service_base_pre.outputs.iam_role_exec_api_arn}"
  cognito_pool_arn       = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_arn}"
  cors                   = "${data.terraform_remote_state.service_base_pre.outputs.web_base_url}"
  service_name           = "${data.terraform_remote_state.setup.outputs.service_name}"
}

output "codebuild_api_name" {
  value = "${module.codebuild_api.name}"
}

output "codebuild_destroy_api_name" {
  value = "${module.codebuild_destroy_api.name}"
}
