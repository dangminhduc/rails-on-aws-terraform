resource "aws_codebuild_project" "web" {
  name           = "${local.prefix}-build-web"
  description    = "${local.prefix}-build-web"
  build_timeout  = "60"
  service_role   = aws_iam_role.codebuild.arn
  encryption_key = aws_kms_alias.codepipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build_web.name
    }
  }

  source {
    type = "CODEPIPELINE"

    buildspec = templatefile("templates/buildspec-web.yml", {
      github_oauth_token_ssm_name = aws_ssm_parameter.for_ecs["github_oauth_token"].name
      rails_master_key_ssm_name   = aws_ssm_parameter.for_ecs["master_key"].name
      database_url_ssm_name       = aws_ssm_parameter.for_ecs["database_url"].name

      rails_env        = local.rails_env
      repository_url   = aws_ecr_repository.rails.repository_url
      s3_bucket_build  = aws_s3_bucket.build.id
      webspec_template = "webspec_template.yml"
      task_def_app     = aws_s3_bucket_object.task_definition["app"].id
      task_def_admin   = aws_s3_bucket_object.task_definition["admin"].id
    })
  }

  # NOTE: railsのイメージビルド後にこのCodeBuildからdb:migrateを実行する
  # RDSへ接続できるようにVPC内でCodeBuildを実行する
  vpc_config {
    vpc_id             = aws_vpc.main.id
    subnets            = aws_subnet.codebuild.*.id
    security_group_ids = [aws_security_group.codebuild.id]
  }

  tags = {
    Name = "${local.prefix}-build-web"
    Env  = local.env
  }
}
