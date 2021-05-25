# NOTE: デフォルトのVPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "default"
  }
}

resource "aws_flow_log" "default_vpc" {
  log_destination      = aws_s3_bucket.logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_default_vpc.default.id

  # NOTE: 先にBucket Policyで許可しないと作成に失敗するために指定。
  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_vpc" "main" {
  cidr_block           = local.cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefix}-vpc"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_flow_log" "main_vpc" {
  log_destination      = aws_s3_bucket.logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  # NOTE: 先にBucket Policyで許可しないと作成に失敗するために指定。
  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip" "nat" {
  count = length(local.azs)
  vpc   = true

  tags = {
    Name = "${local.prefix}-eip-for-nat-gateway${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(local.azs)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${local.prefix}-nat-gw${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.s3"

  tags = {
    Name = "${local.prefix}-vpce-s3"
    Env  = local.env
  }
}
