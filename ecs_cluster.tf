resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-main"

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 0
  }

  tags = {
    Name = "${local.prefix}-main"
    Env  = local.env
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
