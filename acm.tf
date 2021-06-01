resource "aws_acm_certificate" "main" {
  domain_name = local.domain
  subject_alternative_names = [
    "*.${local.domain}",
  ]
  validation_method = "DNS"

  tags = {
    Name = local.service_name
  }
}

# for cloudfront
resource "aws_acm_certificate" "use1" {
  provider = aws.use1

  domain_name = local.domain
  subject_alternative_names = [
    "*.${local.domain}",
  ]
  validation_method = "DNS"

  tags = {
    Name = local.service_name
  }
}
