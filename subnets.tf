resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index * 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "ecs" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 100 + count.index * 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-ecs${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "codebuild" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 103 + count.index * 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-codebuild${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "rds" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 102 + count.index * 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-rds${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "elasticache" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 101 + count.index * 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-elasticache${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}
