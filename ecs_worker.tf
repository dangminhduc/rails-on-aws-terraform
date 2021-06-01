resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.prefix}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs.arn

  container_definitions = templatefile("templates/task_definition_worker.json", {
    rails_env                    = local.rails_env
    image                        = aws_ecr_repository.rails.repository_url
    log_group                    = aws_cloudwatch_log_group.ecs["worker"].name
    rails_master_key_ssm_arn     = aws_ssm_parameter.for_ecs["master_key"].name
    database_url_ssm_arn         = aws_ssm_parameter.for_ecs["database_url"].arn
    database_replica_url_ssm_arn = aws_ssm_parameter.for_ecs["database_replica_url"].arn
    redis_url_ssm_arn            = aws_ssm_parameter.for_ecs["redis_url"].arn
    datadog_api_key_ssm_arn      = aws_ssm_parameter.for_ecs["datadog_api_key"].arn
  })
}

# NOTE: task_definition はデプロイにより更新されていくので、
# dataで最新のtask_definitionを取得し、利用する
# see: https://www.terraform.io/docs/providers/aws/d/ecs_task_definition.html
data "aws_ecs_task_definition" "worker" {
  task_definition = aws_ecs_task_definition.worker.family
}

resource "aws_ecs_service" "worker" {
  name             = "${local.prefix}-worker"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = "${aws_ecs_task_definition.worker.family}:${max(aws_ecs_task_definition.worker.revision, data.aws_ecs_task_definition.worker.revision)}"
  desired_count    = 1
  platform_version = "1.4.0"

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 100
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 0
  }

  network_configuration {
    subnets         = aws_subnet.ecs.*.id
    security_groups = [aws_security_group.ecs.id]
  }
}
