resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset([
    "app",
    "admin",
    "worker",
    "railsc"
  ])
  name              = "${local.prefix}/ecs/${each.key}"
  retention_in_days = 3
  kms_key_id        = aws_kms_key.cloudwatch_log.id

  tags = {
    Env = local.env
  }
}

resource "aws_cloudwatch_log_group" "build_web" {
  name              = "/aws/codebuild/${local.prefix}-build-web"
  retention_in_days = 3
  kms_key_id        = aws_kms_key.cloudwatch_log.id

  tags = {
    Env = local.env
  }
}
