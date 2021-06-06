resource "aws_wafv2_web_acl" "admin" {
  name  = "${local.prefix}-admin"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "${local.prefix}-rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefix}-rate-limit"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${local.prefix}-crs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # NOTE: 画像を扱うことがあるためBody Sizeは無視する。
        excluded_rule {
          name = "SizeRestrictions_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefix}-crs"
      # NOTE: 検知したリクエストの調査のために有効にする
      sampled_requests_enabled = true
    }
  }

  rule {
    name     = "${local.prefix}-sqli"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefix}-sqli"
      # NOTE: 検知したリクエストの調査のために有効にする
      sampled_requests_enabled = true
    }
  }

  tags = {
    Env = local.env
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.prefix}-admin"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "admin" {
  resource_arn = aws_lb.admin.arn
  web_acl_arn  = aws_wafv2_web_acl.admin.arn
}
