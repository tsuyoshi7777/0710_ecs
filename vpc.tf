resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "sample"
  }
}

# Subnet
resource "aws_subnet" "public_0" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.example.id
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.example.id
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_0" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "ap-northeast-1c"
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# route table association
resource "aws_route_table_association" "public_0" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_0.id
}

resource "aws_route_table_association" "public_1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_1.id
}

# security group
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.example.id
}

resource "aws_security_group_rule" "ingress_example_http" {
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_example2_http" {
  from_port         = "8080"
  to_port           = "8080"
  protocol          = "tcp"
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_example_https" {
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_example_rds" {
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.example.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.db.id
}


resource "aws_security_group_rule" "egress_example" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.example.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# security group RDS
resource "aws_security_group" "db" {
    name        = "db_server2"
    description = "It is a security group on db of tf_vpc."
    vpc_id      = aws_vpc.example.id
    tags = {
        Name = "tf_db"
    }
}

resource "aws_security_group_rule" "ingress_db" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = aws_security_group.db.id
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_ip" {
    type                     = "ingress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "tcp"
    security_group_id        = aws_security_group.db.id
    cidr_blocks              = [var.my_ip]
}

resource "aws_security_group_rule" "egress_db" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# security group EC2
resource "aws_security_group" "ec2" {
    name        = "db_server"
    description = "It is a security group on db of tf_vpc."
    vpc_id      = aws_vpc.example.id
    tags = {
        Name = "tf_db"
    }
}

resource "aws_security_group_rule" "ingress_ssh" {
    type                     = "ingress"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_group_id        = aws_security_group.ec2.id
    cidr_blocks              = [var.my_ip]
}

resource "aws_security_group_rule" "egress_ec2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
}
