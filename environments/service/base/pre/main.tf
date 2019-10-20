variable "stage" {}
variable "s3_bucket_terraform_state_id" {}
variable "tfstate_setup_key" {}
variable "resource_prefix" {}
variable "s3_bucket_audit_log_id" {}
variable "s3_bucket_audit_log_bucket_domain_name" {}

provider "aws" {
  version = ">= 2.24"
}

provider "aws" {
  alias   = "useast1"
  version = ">= 2.24"
  region  = "us-east-1"
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

locals {
  service_name             = "${data.terraform_remote_state.setup.outputs.service_name}"
  resource_prefix          = "${var.resource_prefix}"
  cloudformation_api_stack = "${local.service_name}-api-${var.stage}"
  cloudformation_tool_stack = "${local.service_name}-tool-${var.stage}"
}

## tool

module "iam_role_build_tool" {
  source                    = "../../../../modules/iam/build_tool"
  path                      = "../../../../modules/iam/build_tool"
  aws_account_id            = "${data.aws_caller_identity.current.account_id}"
  resource_prefix           = "${local.resource_prefix}"
  cloudformation_tool_stack = "${local.cloudformation_tool_stack}"
}

module "s3_bucket_build_tool" {
  source            = "../../../../modules/s3/bucket/build_tool"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${var.s3_bucket_audit_log_id}"
}

module "iam_role_exec_tool" {
  source                    = "../../../../modules/iam/exec_tool"
  path                      = "../../../../modules/iam/exec_tool"
  aws_account_id            = "${data.aws_caller_identity.current.account_id}"
  resource_prefix           = "${local.resource_prefix}"
  cloudformation_tool_stack = "${local.cloudformation_tool_stack}"
}

module "codebuild_tool" {
  source                  = "../../../../modules/codebuild/tool"
  codecommit_repository   = "${data.terraform_remote_state.setup.outputs.codecommit_infra_repository}"
  iam_role_build_tool_arn = "${module.iam_role_build_tool.arn}"
  s3_bucket_build_tool_id = "${module.s3_bucket_build_tool.id}"
  resource_prefix         = "${var.resource_prefix}"
  stage                   = "${var.stage}"
  iam_role_exec_tool_arn  = "${module.iam_role_exec_tool.arn}"
  service_name            = "${local.service_name}"
}

## dynamo db

module "dynamodb" {
  source          = "../../../../modules/dynamodb"
  resource_prefix = "${local.resource_prefix}"
}

## cognito

module "cognito_pool_api" {
  source            = "../../../../modules/cognito/api"
  resource_prefix   = "${local.resource_prefix}"
}

## waf

module "s3_bucket_waf_log" {
  source            = "../../../../modules/s3/bucket/waf_log"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${var.s3_bucket_audit_log_id}"
}

module "iam_role_waf_log_firehose_to_s3" {
  source          = "../../../../modules/iam/waf_log_firehose_to_s3"
  path            = "../../../../modules/iam/waf_log_firehose_to_s3"
  resource_prefix = "${local.resource_prefix}"
  s3_bucket_arn   = "${module.s3_bucket_waf_log.arn}"
}

resource "aws_kinesis_firehose_delivery_stream" "waf_log" {
  provider    = aws.useast1
  name        = "aws-waf-logs-${local.resource_prefix}"
  destination = "s3"

  s3_configuration {
    role_arn           = "${module.iam_role_waf_log_firehose_to_s3.arn}"
    bucket_arn         = "${module.s3_bucket_waf_log.arn}"
    compression_format = "GZIP"
  }
}

module "waf_acl" {
  source          = "../../../../modules/waf"
  resource_prefix = "${local.resource_prefix}"
  firehose_arn    = "${aws_kinesis_firehose_delivery_stream.waf_log.arn}"
}

## api

module "s3_bucket_api_log" {
  source            = "../../../../modules/s3/bucket/api_log"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${var.s3_bucket_audit_log_id}"
}

module "iam_role_api_log_firehose_to_s3" {
  source          = "../../../../modules/iam/api_log_firehose_to_s3"
  path            = "../../../../modules/iam/api_log_firehose_to_s3"
  resource_prefix = "${local.resource_prefix}"
  s3_bucket_arn   = "${module.s3_bucket_api_log.arn}"
}

resource "aws_kinesis_firehose_delivery_stream" "api_log" {
  name        = "${local.resource_prefix}-api-log-cwl-to-s3-stream"
  destination = "s3"

  s3_configuration {
    role_arn           = "${module.iam_role_api_log_firehose_to_s3.arn}"
    bucket_arn         = "${module.s3_bucket_api_log.arn}"
    compression_format = "GZIP"
  }
}

module "iam_role_api_log_cloudwatchlogs_to_s3_policy" {
  source          = "../../../../modules/iam/api_log_coudwatchlogs_to_s3_policy"
  path            = "../../../../modules/iam/api_log_coudwatchlogs_to_s3_policy"
  aws_account_id  = "${data.aws_caller_identity.current.account_id}"
  resource_prefix = "${local.resource_prefix}"
}

module "iam_role_exec_api" {
  source                   = "../../../../modules/iam/exec_api"
  path                     = "../../../../modules/iam/exec_api"
  aws_account_id           = "${data.aws_caller_identity.current.account_id}"
  resource_prefix          = "${local.resource_prefix}"
  cloudformation_api_stack = "${local.cloudformation_api_stack}"
}

## web

module "s3_bucket_web" {
  source            = "../../../../modules/s3/bucket/web"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${var.s3_bucket_audit_log_id}"
}

module "cloudfront_web" {
  source                          = "../../../../modules/cloudfront/web"
  resource_prefix                 = "${local.resource_prefix}"
  s3_bucket_audit_log_domain_name = "${var.s3_bucket_audit_log_bucket_domain_name}"
  s3_bucket_web_id                = "${module.s3_bucket_web.id}"
  s3_bucket_web_domain_name       = "${module.s3_bucket_web.domain_name}"
  waf_acl_id                      = "${module.waf_acl.id}"
}

## outputs

output "resource_prefix" {
  value = "${local.resource_prefix}"
}

output "cloudformation_tool_stack" {
  value = "${local.cloudformation_tool_stack}"
}

output "cloudformation_api_stack" {
  value = "${local.cloudformation_api_stack}"
}

output "s3_bucket_audit_log_id" {
  value = "${var.s3_bucket_audit_log_id}"
}

output "s3_bucket_audit_log_domain_name" {
  value = "${var.s3_bucket_audit_log_bucket_domain_name}"
}

output "cognito_pool_api_id" {
  value = "${module.cognito_pool_api.id}"
}

output "cognito_pool_api_arn" {
  value = "${module.cognito_pool_api.arn}"
}

output "cognito_pool_api_client_web_id" {
  value = "${module.cognito_pool_api.client_web_id}"
}

output "waf_acl_id" {
  value = "${module.waf_acl.id}"
}

output "iam_role_exec_api_arn" {
  value = "${module.iam_role_exec_api.arn}"
}

output "firehose_delivery_stream_arn" {
  value = "${aws_kinesis_firehose_delivery_stream.api_log.arn}"
}

output "iam_role_api_log_cloudwatchlogs_to_s3_policy_arn" {
  value = "${module.iam_role_api_log_cloudwatchlogs_to_s3_policy.arn}"
}

output "s3_bucket_web_id" {
  value = "${module.s3_bucket_web.id}"
}

output "s3_bucket_web_arn" {
  value = "${module.s3_bucket_web.arn}"
}

output "cloudfront_web_origin_access_identity" {
  value = "${module.cloudfront_web.origin_access_identity}"
}

output "web_base_url" {
  value = "https://${module.cloudfront_web.domain_name}"
}

output "codebuild_tool_name" {
  value = "${module.codebuild_tool.name}"
}
