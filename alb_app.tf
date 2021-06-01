resource "aws_lb" "app" {
  name     = "${local.prefix}-app-lb"
  internal = false # tfsec:ignore:AWS005 ユーザー向けのLBなので、internal設定は不要

  security_groups = [
    aws_security_group.lb_app.id,
  ]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "${local.prefix}-app-lb"
    enabled = true
  }

  tags = {
    Name = "${local.prefix}-app-lb"
    Env  = local.env
  }

  # NOTE: バケットポリシーが作成される前に、ALBのログ設定が実行されてしまい、Access Deniedエラーが発生する
  #       これを回避するために、depends_onでbucket_policyを指定する。
  depends_on = [
    aws_s3_bucket_policy.logs
  ]
}

resource "aws_lb_target_group" "app" {
  for_each = toset(["blue", "green"])

  name              = "${local.prefix}-app-${each.key}"
  port              = 3000
  protocol          = "HTTP"
  vpc_id            = aws_vpc.main.id
  target_type       = "ip"
  proxy_protocol_v2 = false

  health_check {
    interval            = 30
    path                = "/healthcheck"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = 200
  }

  tags = {
    Name = "${local.prefix}-app-${each.key}"
    Env  = local.env
  }
}

resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }

  depends_on = [aws_lb_target_group.app]
}

resource "aws_lb_listener_rule" "app_listener_https_host" {
  listener_arn = aws_lb_listener.app_https.arn
  priority     = 100

  action {
    target_group_arn = aws_lb_target_group.app["blue"].arn
    type             = "forward"
  }

  condition {
    host_header {
      # NOTE: ドメイン名で制御する
      values = [local.cloudfront_domain]
    }
  }

  # NOTE: CodeDeployによるBlue/Green Deploymentで変更される箇所を無視
  lifecycle {
    ignore_changes = [
      action,
    ]
  }
}
