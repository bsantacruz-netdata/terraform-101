data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_internet_gateway" "this" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Name = "terraform101"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = var.subnet_az
  cidr_block        = "10.20.30.0/28" #cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)
}

resource "aws_route_table" "this" {
  vpc_id = data.aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "terraform101"
  }
}

