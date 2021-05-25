# tfsec:ignore:AWS002
resource "aws_s3_bucket" "logs" {
  bucket = "${local.env}.${local.service_name}.logs"

  # NOTE: S3 loggingを有効にするためAmazon S3 group Log Deliveryを権限を付与する
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
  grant {
    permissions = [
      "READ_ACP",
      "WRITE",
    ]
    type = "Group"
    uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
  }

  grant {
    id          = data.aws_canonical_user_id.current.id
    permissions = ["FULL_CONTROL"]
    type        = "CanonicalUser"
  }

  # NOTE: CloudFrontがロギングを有効する際に付与する権限もTerraformで管理するため、
  #       aclではなくgrantを利用して管理する。
  # CloudFront log delivery アカウントの canonical ID を取得する data ソースがない為、直接 id 指定する。
  # see: https://github.com/hashicorp/terraform-provider-aws/issues/12512
  grant {

    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    permissions = ["FULL_CONTROL"]
    type        = "CanonicalUser"
  }

  versioning {
    enabled = true
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${local.env}.${local.service_name}.logs"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.alb.arn]
    }
  }

  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
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

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}
