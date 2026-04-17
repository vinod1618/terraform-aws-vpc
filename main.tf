resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = local.vpc_final_tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # VPC association

  tags = local.final_igw_tags
}


resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
        },
        var.public_subnet_tags
        )
}


resource "aws_subnet" "Private" {
  count = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
        },
        var.private_subnet_tags
        )
}



resource "aws_subnet" "databse" {
  count = length(var.database_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-databse-${local.az_names[count.index]}"
        },
        var.database_subnet_tags
        )
}


# route tables


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-public"
        },
        var.public_route_table_tags
        )
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-private"
        },
        var.private_route_table_tags
        )
}


resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-database"
        },
        var.database_route_table_tags
        )
}



resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}


resource "aws_eip" "nat" {
  domain                    = "vpc"

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}-nat"
        },
        var.eip_tags
        )

}

# NAT creation

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # we are creating this in us-east-1a

  tags = merge(
        local.common_tags,
        {
          Name = "${var.project}-${var.environment}"
        },
        var.nat_gateway_tags
        )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}


resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.main.id
}



resource "aws_route" "public" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

