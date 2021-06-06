resource "aws_wafv2_web_acl" "cloudfront_app" {
  provider = aws.use1

  name  = "${local.prefix}-cloudfront-app"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "${local.prefix}-rate-limit"
    priority = 0

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
    priority = 1

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
    priority = 2

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

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${local.prefix}-cloudfront-app"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${local.prefix}-cloudfront-app"
    Env  = local.env
  }
}

resource "aws_wafv2_web_acl" "allow_headers" {
  name  = "${local.prefix}-allow-headers"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "${local.prefix}-allow-headers"
    priority = 0

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        positional_constraint = "EXACTLY"
        search_string         = local.cloudfront_shared_key

        field_to_match {
          single_header {
            name = "x-cloudfront-shared-key"
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.prefix}-allow-headers"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${local.prefix}-allow-headers"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${local.prefix}-allow-headers"
    Env  = local.env
  }
}

resource "aws_wafv2_web_acl_association" "app" {
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.allow_headers.arn
}
