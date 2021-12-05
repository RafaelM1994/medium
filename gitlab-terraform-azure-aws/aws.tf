#VPC
resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "terraform"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = var.aws-location

  tags = {
    Name = "terraform"
  }
}

#Network Interface
resource "aws_network_interface" "if01" {
  subnet_id   = aws_subnet.subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

#Instance01
resource "aws_instance" "instance01" {
  ami           = "ami-0b0af3577fe5e3532" # us-west-1
  instance_type = "t2.micro"
  availability_zone = var.aws-location

  network_interface {
    network_interface_id = aws_network_interface.if01.id
    device_index         = 0
  }

}