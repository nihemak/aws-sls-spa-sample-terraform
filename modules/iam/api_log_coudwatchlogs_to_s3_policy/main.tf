variable "path" {}
variable "aws_account_id" {}
variable "resource_prefix" {}

## role

data "template_file" "iam_assume_role_policy_api_log_cloudwatchlogs_to_firehose" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "api_log_cloudwatchlogs_to_firehose" {
  name               = "${var.resource_prefix}-api-log-cwl-to-firehose-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_api_log_cloudwatchlogs_to_firehose.rendered}"
}

## role policy

data "template_file" "iam_policy_api_log_cloudwatchlogs_to_firehose" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    aws_account_id = "${var.aws_account_id}"
    iam_role_arn   = "${aws_iam_role.api_log_cloudwatchlogs_to_firehose.arn}"
  }
}

resource "aws_iam_role_policy" "api_log_cloudwatchlogs_to_firehose" {
  name   = "${var.resource_prefix}-api-log-cwl-to-firehose-policy-01"
  role   = "${aws_iam_role.api_log_cloudwatchlogs_to_firehose.id}"
  policy = "${data.template_file.iam_policy_api_log_cloudwatchlogs_to_firehose.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.api_log_cloudwatchlogs_to_firehose.arn}"
}
