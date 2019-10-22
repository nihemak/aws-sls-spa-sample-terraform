variable "resource_prefix" {}
variable "firehose_arn" {}
variable "rule_size_constraint_id" {}
variable "rule_sql_injection_match_id" {}
variable "rule_xss_match_id" {}

resource "aws_waf_web_acl" "web" {
  name        = "${var.resource_prefix}-WebAttackProtection"
  metric_name = "${replace("${var.resource_prefix}", "-", "")}WebAttackProtection"

  default_action {
    type = "ALLOW"
  }

  rules {
    action {
      type = "COUNT"
    }

    priority = 1
    rule_id  = "${var.rule_size_constraint_id}"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = "${var.rule_sql_injection_match_id}"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 3
    rule_id  = "${var.rule_xss_match_id}"
  }

  logging_configuration {
    log_destination = "${var.firehose_arn}"
  }
}

## outputs

output "id" {
  value = "${aws_waf_web_acl.web.id}"
}
