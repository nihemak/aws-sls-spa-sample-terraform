variable "resource_prefix" {}

## conditions

resource "aws_waf_sql_injection_match_set" "common" {
  name = "${var.resource_prefix}-CommonAttackProtectionSqliMatch"

  sql_injection_match_tuples {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  sql_injection_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  sql_injection_match_tuples {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  sql_injection_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  sql_injection_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_waf_xss_match_set" "common" {
  name = "${var.resource_prefix}-CommonAttackProtectionXssMatch"

  xss_match_tuples {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  xss_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  xss_match_tuples {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  xss_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  xss_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_waf_size_constraint_set" "common" {
  name = "${var.resource_prefix}-CommonAttackProtectionLargeBodyMatch"

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = "8192"

    field_to_match {
      type = "BODY"
    }
  }
}

## rules

resource "aws_waf_rule" "common_sql_injection_match" {
  name        = "${var.resource_prefix}-CommonAttackProtectionSqliRule"
  metric_name = "${replace("${var.resource_prefix}", "-", "")}CommonAttackProtectionSqliRule"

  predicates {
    data_id = "${aws_waf_sql_injection_match_set.common.id}"
    negated = false
    type    = "SqlInjectionMatch"
  }
}

resource "aws_waf_rule" "common_xss_match" {
  name        = "${var.resource_prefix}-CommonAttackProtectionXssRule"
  metric_name = "${replace("${var.resource_prefix}", "-", "")}CommonAttackProtectionXssRule"

  predicates {
    data_id = "${aws_waf_xss_match_set.common.id}"
    negated = false
    type    = "XssMatch"
  }
}

resource "aws_waf_rule" "common_size_constraint" {
  name        = "${var.resource_prefix}-CommonAttackProtectionLargeBodyMatchRule"
  metric_name = "${replace("${var.resource_prefix}", "-", "")}CommonAttackProtectionLargeBodyMatchRule"

  predicates {
    data_id = "${aws_waf_size_constraint_set.common.id}"
    negated = false
    type    = "SizeConstraint"
  }
}

## acl

resource "aws_waf_web_acl" "common" {
  name        = "${var.resource_prefix}-CommonAttackProtection"
  metric_name = "${replace("${var.resource_prefix}", "-", "")}CommonAttackProtection"

  default_action {
    type = "ALLOW"
  }

  rules {
    action {
      type = "COUNT"
    }

    priority = 1
    rule_id  = "${aws_waf_rule.common_size_constraint.id}"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = "${aws_waf_rule.common_sql_injection_match.id}"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 3
    rule_id  = "${aws_waf_rule.common_xss_match.id}"
  }
}

## outputs

output "id" {
  value = "${aws_waf_web_acl.common.id}"
}
