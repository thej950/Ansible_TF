resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT-1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.RT-1.id
}

resource "aws_security_group" "sg-1" {
  vpc_id      = aws_vpc.myvpc.id
  name        = "websg"
  description = "Allow TLS Inbound Traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "websg-1"
  }
}

resource "aws_key_pair" "awskey1" {
  key_name   = "terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoiZLoj3+KnBzp1Ot+MTB7mgT2KX/u5ssM8TeBDxx3UxcTdRErS0AuRuNPgvdiVYfZ3R34KDIxbERT27NxEALfNYbLhU+FQ3IpduPe8imCKLHYgYzxwOQWuMEkfV9wevRxW7dcto/12MTmGKg8anE93l4uC/wet6htkLPeRymf/Dk0kCyGz1CVtdLqei78lUdAPgluPH28iK9wtLKVw9cm344DmDPi0wPVMFGzPs7Lq3j1XpqpG7ZO7ECiluqbw6wRPY9KLA5Eux7ng4qSLhi02PMDwuhQbTC97Onu89CbGhmQreZLx7hXcbkCax3+vduae7lDV/QsqEeOn6ndKNPH8BhSUpRF+SLpWGVpps6S+nlUvw9uoBML3sWOM25lDGBaYsttkIiXL2W0GLtwjRZWyolBOVjkmOvgjekBqCrYxPlQPiJh0R9Kns+3MAAk0lD3faNLuWwE3IRaFePghQvFY3nKOAW+LsbNCq5xtesbNzXwSLlo4cdU4FjKob3uots= DELL@Navathej"
}

resource "aws_instance" "controller" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.sg-1.id]
  private_ip             = "10.0.1.10"

  user_data = base64encode(file("workspace/controller.sh"))


  provisioner "file" {
    source      = "workspace"
    destination = "/home/ubuntu/workspace"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("workspace/sshkeys/terraform")
      host        = aws_instance.controller.public_ip
    }
  }
  tags = {
    Name = "Controller-Machine"
  }
}

resource "aws_instance" "worker-1" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.sg-1.id]
  private_ip             = "10.0.1.11"

  tags = {
    Name = "worker-mchine-1"
  }
}


resource "aws_instance" "worker-2" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.sg-1.id]
  private_ip             = "10.0.1.12"
 
 tags = {
   Name = "worker-machine-2"
 }
}
