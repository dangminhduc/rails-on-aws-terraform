resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.azs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "ecs" {
  count  = length(local.azs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-ecs${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route" "ecs" {
  count                  = length(local.azs)
  route_table_id         = element(aws_route_table.ecs.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "ecs" {
  count          = length(local.azs)
  subnet_id      = element(aws_subnet.ecs.*.id, count.index)
  route_table_id = element(aws_route_table.ecs.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "ecs_s3" {
  count           = length(local.azs)
  route_table_id  = element(aws_route_table.ecs.*.id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table" "codebuild" {
  count  = length(local.azs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-codebuild${count.index}"
    Env  = local.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route" "codebuild" {
  count                  = length(local.azs)
  route_table_id         = element(aws_route_table.codebuild.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "codebuild" {
  count          = length(local.azs)
  subnet_id      = element(aws_subnet.codebuild.*.id, count.index)
  route_table_id = element(aws_route_table.codebuild.*.id, count.index)
}
