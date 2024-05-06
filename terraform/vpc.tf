resource "aws_vpc" "msaicharan_vpc" {
  cidr_block = "17.2.0.0/16"
  tags = {
    Name = "msaicharan_vpc"
  }
}

resource "aws_subnet" "msaicharan_public_subnet_1" {
  vpc_id                  = aws_vpc.msaicharan_vpc.id
  cidr_block              = "17.2.1.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "msaicharan_public_subnet_1"
  }
}
resource "aws_subnet" "msaicharan_public_subnet_2" {
  vpc_id                  = aws_vpc.msaicharan_vpc.id
  cidr_block              = "17.2.2.0/24"
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "msaicharan_public_subnet_2"
  }
}
resource "aws_subnet" "msaicharan_private_subnet" {
  vpc_id            = aws_vpc.msaicharan_vpc.id
  availability_zone = var.availability_zone_1
  cidr_block        = "17.2.3.0/24"
  tags = {
    Name = "msaicharan_private_subnet"
  }
}

resource "aws_internet_gateway" "msaicharan_igw" {
  vpc_id = aws_vpc.msaicharan_vpc.id
  tags = {
    Name = "msaicharan_igw"
  }

}

resource "aws_route_table" "msaicharan_routetable_public" {
  vpc_id = aws_vpc.msaicharan_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.msaicharan_igw.id
  }
  tags = {
    Name = "msaicharan_routetable_public"
  }
}
resource "aws_route_table_association" "msaicharan_public_1-rt_attach" {
  subnet_id      = aws_subnet.msaicharan_public_subnet_1.id
  route_table_id = aws_route_table.msaicharan_routetable_public.id
}

resource "aws_route_table_association" "msaicharan_public_2-rt_attach" {
  subnet_id      = aws_subnet.msaicharan_public_subnet_2.id
  route_table_id = aws_route_table.msaicharan_routetable_public.id
}

resource "aws_route_table" "msaicharan_routetable_private" {
  vpc_id = aws_vpc.msaicharan_vpc.id
  tags = {
    Name = "msaicharan_routetable_public"
  }
}
resource "aws_route_table_association" "rt_associate_private_2" {
  subnet_id      = aws_subnet.msaicharan_private_subnet.id
  route_table_id = aws_route_table.msaicharan_routetable_private.id
}