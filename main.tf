# Create a VPC
resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "dev"
  }
}

# mtc_public_subnet1 &  map_public_ip_on_launch
resource "aws_subnet" "mtc_public_subnet1" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public-subnet"
  }
}

# mtc_public_subnet2
resource "aws_subnet" "mtc_public_subnet2" {
  vpc_id     = aws_vpc.mtc_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "dev-public-subnet2"
  }
}

# aws_internet_gateway
resource "aws_internet_gateway" "public-gw" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-public-gw"
  }
}

# route table

resource "aws_route_table" "mtcRoute-table" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-mtcRoute-table"
  }
}

# default route
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtcRoute-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public-gw.id
}

# route association

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mtc_public_subnet1.id
  route_table_id = aws_route_table.mtcRoute-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.mtc_public_subnet2.id
  route_table_id = aws_route_table.mtcRoute-table.id
}

# Security group
resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-mtc-sg"
  }
}

# Create keypair
# ssh-keygen -t ed25519  + Enter; add path with keypair to save key [: C:\Users\user/.ssh/keypair]

resource "aws_key_pair" "keypair_auth" {
  key_name   = "keypair"
  public_key = file("~/.ssh/keypair.pub")
}

# create an instance now & include userdata.tpl

resource "aws_instance" "webserver" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.keypair_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet1.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "web-server"
  }
  
  # include provisioner and templatefile
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/keypair"
      })
      interpreter = var.host_os == "windows" ? ["PowerShell", "-Command"] : ["bash", "-c"]
      #interpreter = ["PowerShell", "-Command"]
      ##interpreter = ["bash", "-c"]   #use for linux
  }

}
