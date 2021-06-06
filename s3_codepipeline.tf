# NOTE: バケットオブジェクトはデプロイ用のファイルなので不要と判断
# tfsec:ignore:AWS077
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${local.env}.${local.service_name}.codepipeline"
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "codepipeline-artifacts/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_alias.codepipeline.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name = "${local.env}.${local.service_name}.codepipeline"
    Env  = local.env
  }
}

data "aws_iam_policy_document" "codepipeline_bucket" {
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.codepipeline.arn,
      "${aws_s3_bucket.codepipeline.arn}/*",
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

resource "aws_s3_bucket_policy" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_bucket.json
}
