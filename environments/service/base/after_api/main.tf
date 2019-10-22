variable "stage" {}
variable "s3_bucket_terraform_state_id" {}
variable "tfstate_service_base_pre_key" {}
variable "apigw_api_id" {}

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
  s3_bucket_audit_log_id   = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_audit_log_id}"
  cloudformation_tool_stack = "${data.terraform_remote_state.service_base_pre.outputs.cloudformation_tool_stack}"
}

module "s3_bucket_apigw_log" {
  source            = "../../../../modules/s3/bucket/apigw_log"
  resource_prefix   = "${local.resource_prefix}"
  logging_bucket_id = "${local.s3_bucket_audit_log_id}"
}

module "iam_role_apigw_firehose_to_s3" {
  source          = "../../../../modules/iam/apigw_firehose_to_s3"
  path            = "../../../../modules/iam/apigw_firehose_to_s3"
  resource_prefix = "${local.resource_prefix}"
  s3_bucket_arn   = "${module.s3_bucket_apigw_log.arn}"
  aws_account_id            = "${data.aws_caller_identity.current.account_id}"
  cloudformation_tool_stack = "${local.cloudformation_tool_stack}"
}

resource "aws_kinesis_firehose_delivery_stream" "apigw" {
  name        = "${local.resource_prefix}-apigw-cwl-to-s3-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = "${module.iam_role_apigw_firehose_to_s3.arn}"
    bucket_arn         = "${module.s3_bucket_apigw_log.arn}"
    compression_format = "GZIP"

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "arn:aws:lambda:ap-northeast-1:${data.aws_caller_identity.current.account_id}:function:${local.cloudformation_tool_stack}-logsProcessor:$LATEST"
        }
      }
    }
  }
}

module "iam_role_apigw_cloudwatchlogs_to_s3_policy" {
  source          = "../../../../modules/iam/apigw_coudwatchlogs_to_s3_policy"
  path            = "../../../../modules/iam/apigw_coudwatchlogs_to_s3_policy"
  aws_account_id  = "${data.aws_caller_identity.current.account_id}"
  resource_prefix = "${local.resource_prefix}"
}

resource "aws_cloudwatch_log_subscription_filter" "apigw_logfilter" {
  name            = "${local.resource_prefix}-apigw_logfilter"
  role_arn        = "${module.iam_role_apigw_cloudwatchlogs_to_s3_policy.arn}"
  log_group_name  = "/aws/api-gateway/${local.cloudformation_api_stack}"
  filter_pattern  = ""
  destination_arn = "${aws_kinesis_firehose_delivery_stream.apigw.arn}"
}

module "cloudfront_api" {
  source                           = "../../../../modules/cloudfront/api"
  resource_prefix                  = "${local.resource_prefix}"
  stage                            = "${var.stage}"
  apigw_api_domain_name            = "${var.apigw_api_id}.execute-api.ap-northeast-1.amazonaws.com"
  s3_bucket_audit_log_domain_name  = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_audit_log_domain_name}"
  waf_acl_id                       = "${data.terraform_remote_state.service_base_pre.outputs.waf_acl_api_id}"
}

output "api_base_url" {
  value = "https://${module.cloudfront_api.domain_name}"
}
