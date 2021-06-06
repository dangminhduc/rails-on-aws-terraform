# CodeBuild で利用する定義ファイル等格納用 S3 Bucket
resource "aws_s3_bucket" "build" {
  bucket = "${local.env}.${local.service_name}.build"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "codebuild-templates/"
  }
}

data "aws_iam_policy_document" "build" {
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.build.arn,
      "${aws_s3_bucket.build.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "build" {
  bucket = aws_s3_bucket.build.id
  policy = data.aws_iam_policy_document.build.json
}

resource "aws_s3_bucket_object" "task_definition" {
  for_each = {
    "app" = {
      family    = aws_ecs_task_definition.app.family
      task_def  = "task_definition_app.json"
      task_role = aws_iam_role.ecs_task_app.arn
    }
    "admin" = {
      family    = aws_ecs_task_definition.admin.family
      task_def  = "task_definition_admin.json"
      task_role = aws_iam_role.ecs_task_admin.arn
    }
  }
  bucket = aws_s3_bucket.build.id
  key    = each.value.task_def
  content = templatefile("templates/task_definition.json", {
    server_role                  = each.key
    family                       = each.value.family
    task_role_arn                = each.value.task_role
    task_exec_role_arn           = aws_iam_role.ecs.arn
    repository_url               = aws_ecr_repository.rails.repository_url
    log_group                    = aws_cloudwatch_log_group.ecs[each.key].name
    rails_env                    = local.rails_env
    rails_master_key_ssm_arn     = aws_ssm_parameter.for_ecs["master_key"].arn
    database_url_ssm_arn         = aws_ssm_parameter.for_ecs["database_url"].arn
    database_replica_url_ssm_arn = aws_ssm_parameter.for_ecs["database_replica_url"].arn
    redis_url_ssm_arn            = aws_ssm_parameter.for_ecs["redis_url"].arn
    datadog_api_key_ssm_arn      = aws_ssm_parameter.for_ecs["datadog_api_key"].arn
  })
}

resource "aws_s3_bucket_object" "spec_template" {
  bucket  = aws_s3_bucket.build.id
  key     = "webspec_template.yml"
  content = file("templates/webspec_template.yml")
}
