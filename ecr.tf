resource "aws_ecr_repository" "rails" {
  name                 = "${local.prefix}-rails"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.key_id
  }
}

resource "aws_ecr_lifecycle_policy" "rails" {
  repository = aws_ecr_repository.rails.name

  policy = templatefile("templates/ecr_lifecycle_policy.tpl", {
    untagged_expire_days = 14
    keep_latest_count    = 50
  })
}
