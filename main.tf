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
  public_key = file("workspace/sshkeys/terraform.pub") # Use your public key path
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

