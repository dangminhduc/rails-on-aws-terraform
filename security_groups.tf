resource "aws_security_group" "mysql" {
  description = "Security group for mysql databases"
  name        = "${local.prefix}-mysql"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-mysql"
    Env  = local.env
  }
}

resource "aws_security_group_rule" "mysql_ecs" {
  description              = "Allow app ecs task to connect to the database"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.mysql.id
}

resource "aws_security_group_rule" "mysql_codebuild" {
  description              = "Allow Codebuild instances to connect to the database to execute db rake task"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.codebuild.id
  security_group_id        = aws_security_group.mysql.id
}

resource "aws_security_group_rule" "mysql_egress" {
  description       = "Egress rule for database instances"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = [local.cidr]
  security_group_id = aws_security_group.mysql.id
}

resource "aws_security_group" "lb_app" {
  description = "Security Group for app LB"
  name        = "${local.prefix}-lb-app"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-lb-app"
    Env  = local.env
  }
}

resource "aws_security_group" "lb_admin" {
  description = "Security Group for admin LB"
  name        = "${local.prefix}-lb-admin"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-lb-admin"
    Env  = local.env
  }
}

resource "aws_security_group_rule" "lb_app_https" {
  description       = "Allow https to app LB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS006 CloudFront からアクセスできる様、インターネットに公開する。STGのIP制限はWAF側に設定する
  security_group_id = aws_security_group.lb_app.id
}

resource "aws_security_group_rule" "lb_admin_https" {
  description       = "Allow access from Office to admin site"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.office_ips
  security_group_id = aws_security_group.lb_admin.id
}

resource "aws_security_group_rule" "lb_app_egress" {
  description       = "Egress rule for app LB"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007 ユーザー向けのLBなので、Egressルールを無視する
  security_group_id = aws_security_group.lb_app.id
}

resource "aws_security_group" "ecs" {
  description = "Security group for ECS task"
  name        = "${local.prefix}-ecs"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-ecs-app"
    Env  = local.env
  }
}

resource "aws_security_group_rule" "ecs_app_base" {
  description              = "Allow accessing to rails port on ECS task"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_app.id
  security_group_id        = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "ecs_egress" {
  description       = "Egress rule for ECS task"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007 datadog docker イメージpullが必要なので、インターネットへの通信を許可する
  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "lb_admin_egress" {
  description       = "Egress rule for admin LB"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007 ユーザー向けのLBなので、Egressルールを無視する
  security_group_id = aws_security_group.lb_admin.id
}

resource "aws_security_group_rule" "ecs_admin_base" {
  description              = "Allow accessing to rails port on ECS task"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_admin.id
  security_group_id        = aws_security_group.ecs.id
}

resource "aws_security_group" "redis" {
  name        = "${local.prefix}-redis"
  description = "Allow Redis from ECS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-redis"
    Env  = local.env
  }
}

resource "aws_security_group_rule" "redis_ecs" {
  description              = "Allow ecs task to access redis cluster"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.redis.id
}

resource "aws_security_group_rule" "redis_egress" {
  description       = "Egress traffic rule for redis"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = [local.cidr]
  security_group_id = aws_security_group.redis.id
}

resource "aws_security_group" "codebuild" {
  name        = "${local.prefix}-codebuild"
  description = "CodeBuild in VPC"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-codebuild"
    Env  = local.env
  }
}

resource "aws_security_group_rule" "codebuild_egress" {
  description       = "Egress rule for Codebuild instances"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007 S3に置いてあるのソースコードを取りに行くため、インターネットへの通信が必要
  security_group_id = aws_security_group.codebuild.id
}
