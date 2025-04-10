locals {
  vpc_cidr      = "10.0.0.0/16"
  subnet_1_cidr = "10.0.1.0/24"
  machine_image = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name      = "terraform"

  ssh_key_path         = "workspace/sshkeys/terraform"
  ssh_pub_key_path     = "workspace/sshkeys/terraform.pub"
  user_data_controller = "workspace/controller.sh"

  static_private_ips = {
    controller = "10.0.1.10"
    worker_1   = "10.0.1.11"
    worker_2   = "10.0.1.12"
  }

  instance_common_tags = {
    Environment = "Dev"
    Project     = "EKS-Cluster"
  }
}

#==============outputs=====================
output "controller_public_ip" {
  description = "Public IP of the Controller instance"
  value       = aws_instance.controller.public_ip
}

#==============vpc=====================
resource "aws_vpc" "myvpc" {
  cidr_block = local.vpc_cidr
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = local.subnet_1_cidr
  map_public_ip_on_launch = true
}

#========internet-gateway===============
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt_1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}

#=============security-group==================
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.myvpc.id
  name   = "web-sg"

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
    Name = "web-sg"
  }
}

#===========key-pair====================
resource "aws_key_pair" "default" {
  key_name   = local.key_name
  public_key = file(local.ssh_pub_key_path)
}

#===========controller==================
resource "aws_instance" "controller" {
  ami                    = local.machine_image
  instance_type          = local.instance_type
  key_name               = local.key_name
  subnet_id              = aws_subnet.subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  private_ip             = local.static_private_ips.controller
  user_data              = base64encode(file(local.user_data_controller))

  provisioner "file" {
    source      = "workspace"
    destination = "/home/ubuntu/workspace"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.ssh_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(local.instance_common_tags, {
    Name = "controller"
  })
}
#===============worker-1===================
resource "aws_instance" "worker_1" {
  ami                    = local.machine_image
  instance_type          = local.instance_type
  key_name               = local.key_name
  subnet_id              = aws_subnet.subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  private_ip             = local.static_private_ips.worker_1

  tags = merge(local.instance_common_tags, {
    Name = "worker-1"
  })
}

#==============worker-2======================
resource "aws_instance" "worker_2" {
  ami                    = local.machine_image
  instance_type          = local.instance_type
  key_name               = local.key_name
  subnet_id              = aws_subnet.subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  private_ip             = local.static_private_ips.worker_2

  tags = merge(local.instance_common_tags, {
    Name = "worker-2"
  })
}

