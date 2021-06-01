resource "aws_ecs_task_definition" "app" {
  family                   = "${local.prefix}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs.arn

  # NOTE: タスク定義は初回以外はCodeDeploy経由での更新のみとなる。
  #       (deployment_controller に CODE_DEPLOY を指定しているため)
  #       初回構築用にダミーのタスク定義を指定する。
  #       実際にdeployされるコンテナと同じ様に3000番ポートで応答し、healthcheckにも応答するようにcommandを設定している。
  container_definitions = file("templates/container_definitions_dummy.json")
}

resource "aws_ecs_service" "app" {
  name             = "${local.prefix}-app"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.app.arn
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

  load_balancer {
    target_group_arn = aws_lb_target_group.app["blue"].id
    container_name   = "web"
    container_port   = "3000"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # NOTE: 依存関係的にTarget Groupの生成はまってくれるが、<target group名> does not have an associated load balancer. が発生してしまう。
  #       この問題を回避するために、aws_lb_listenerをdepends_onに追加することで、Target Groupがload balancerに紐づくのを待ってからecs_serviceを作成する。
  #
  # 参考:
  #   - https://github.com/hashicorp/terraform/issues/12634
  #   - https://github.com/terraform-providers/terraform-provider-aws/issues/3495
  depends_on = [
    aws_lb_listener.app_https,
  ]

  # NOTE: CodeDeployによるBlue/Green Deploymentで変更される箇所を無視
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
    ]
  }
}
