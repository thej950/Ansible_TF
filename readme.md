# Setup Ansible cluster 
- create a user with AdministrationAccess (user-admin) on aws cloud 
- Generate accesskeys and secret accesskeys for to login from CLI 
- login into local machie where terraform will be implemented 

        # aws configure 
        accesskey: XXXXXXXXX
        secretkey: XXXXXXXXXXX
        region   : us-east-1
        default  : text 



# Now create a terraform file to setup ansible environemnt on aws cloud 
- create providers in providers block and specifying region to work 

        provider "aws" {
            region = "us-east-1"
        }

- create resource of aws_vpc with myvpc with specific range (10.0.0.0/16)

        resource "aws_vpc" "myvpc" {
            cidr_block = var.cidr
        }

- create resource aws_subnet with subnet-1 10.0.1.0/24 under myvpc range 

        resource "aws_subnet" "subnet-1" {
            vpc_id                  = aws_vpc.myvpc.id
            cidr_block              = "10.0.1.0/24"
            map_public_ip_on_launch = true
        }

- create a resource of aws_internet_gateway with igw under myvpc To provide internet access 

        resource "aws_internet_gateway" "igw" {
            vpc_id = aws_vpc.myvpc.id
        }

- create resource of aws_route_table as a  RT-1 under myvpc and edit route to igw 

         resource "aws_route_table" "RT-1" {
            vpc_id = aws_vpc.myvpc.id

            route {
                cidr_block = "0.0.0.0/0"
                gateway_id = aws_internet_gateway.igw.id
            }
        }

- create a resource of aws_route_table_association as rta-1 with associate with subnet-1   route association with attched to subent-1 (10.0.1.0/24)

        resource "aws_route_table_association" "rta-1" {
            subnet_id      = aws_subnet.subnet-1.id
            route_table_id = aws_route_table.RT-1.id
        }


- create a resource aws_security_group as a sg-1  under myvpc allow  ssh to connect machine remotely 
    

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

>> From above code security group ingress is for inbound rules and egress for outbound rules 

- create a resource aws_key_pair with awskey1 ( this is for usefull to connect our machines )


        resource "aws_key_pair" "awskey1" {
            key_name   = "terraform"
            public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoiZLoj3+KnBzp1Ot+MTB7mgT2KX/u5ssM8TeBDxx3UxcTdRErS0AuRuNPgvdiVYfZ3R34KDIxbERT27NxEALfNYbLhU+FQ3IpduPe8imCKLHYgYzxwOQWuMEkfV9wevRxW7dcto/12MTmGKg8anE93l4uC/wet6htkLPeRymf/Dk0kCyGz1CVtdLqei78lUdAPgluPH28iK9wtLKVw9cm344DmDPi0wPVMFGzPs7Lq3j1XpqpG7ZO7ECiluqbw6wRPY9KLA5Eux7ng4qSLhi02PMDwuhQbTC97Onu89CbGhmQreZLx7hXcbkCax3+vduae7lDV/QsqEeOn6ndKNPH8BhSUpRF+SLpWGVpps6S+nlUvw9uoBML3sWOM25lDGBaYsttkIiXL2W0GLtwjRZWyolBOVjkmOvgjekBqCrYxPlQPiJh0R9Kns+3MAAk0lD3faNLuWwE3IRaFePghQvFY3nKOAW+LsbNCq5xtesbNzXwSLlo4cdU4FjKob3uots= DELL@Navathej"
        }

- create resource aws_instance with name controller 10.0.1.10 with ansible setup in userdata and using file provision to copy local workspace folder into remote ansible Controller

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

>> above instance created inder subnet-1 

- create a resource aws_instance with worker-1 (10.0.1.11) and worker-2 (10.0.1.12)

- worker-1

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


- worker-2 

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

>> from above Two machines are managed nodes 


# To check ansible cluster working properly 

- Connect to controller using public ip 

        # ssh -i terraform ubuntu@23.89.44.45

- Now check ansible version 

        $ ansible --version 

- Goto workspace folder excute below command For pinging or not 

        $ ansible all -i hosts -m ping 

- To check date of the remote hosts 

        $ ansible all -i hosts -a 'date' 

# output of ping 

        ubuntu@ip-10-0-1-10:~/workspace$ ansible all -i hosts -m ping
        10.0.1.12 | SUCCESS => {
            "ansible_facts": {
                "discovered_interpreter_python": "/usr/bin/python3"
            },
            "changed": false,
            "ping": "pong"
        }
        10.0.1.11 | SUCCESS => {
            "ansible_facts": {
                "discovered_interpreter_python": "/usr/bin/python3"
            },
            "changed": false,
            "ping": "pong"
        }
        ubuntu@ip-10-0-1-10:~/workspace$
