resource "aws_cloudfront_distribution" "app" {
  origin {
    domain_name = local.domain_lb_app
    origin_id   = "alb-app"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-cloudfront-shared-key"
      value = local.cloudfront_shared_key
    }
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_app.arn

  enabled         = true
  is_ipv6_enabled = true

  logging_config {
    include_cookies = true
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront-app"
  }

  aliases = [local.cloudfront_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE", "PATCH"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb-app"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["*"]
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/packs/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-app"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = ["Host"]
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false

    acm_certificate_arn      = aws_acm_certificate.use1.arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }

  tags = {
    Name = "${local.prefix}-app"
    Env  = local.env
  }
}
