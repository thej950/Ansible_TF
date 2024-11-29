## **Setup Ansible Cluster Using Terraform**

### **1. Pre-requisites:**
- **Create AWS IAM User:**
  - User Name: `user-admin`
  - Attach Policy: `AdministratorAccess`
  - Generate Access and Secret Keys.

- **Configure AWS CLI on your local machine:**
  ```bash
  aws configure
  ```
  Provide:
  - **Access Key**: `XXXXXXXXX`
  - **Secret Key**: `XXXXXXXXXX`
  - **Region**: `us-east-1`
  - **Output Format**: `text`

---

### **2. Terraform Commands**
Run the following commands in sequence to deploy the infrastructure:
```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy # Use only when cleaning up resources
```

---

### **3. Terraform Configuration File**

#### **Provider Configuration**
```hcl
provider "aws" {
  region = "us-east-1"
}
```

#### **Variables Block** (optional for better modularity)
```hcl
variable "cidr" {
  default = "10.0.0.0/16"
}
```

#### **VPC and Subnet Configuration**
```hcl
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
```

#### **Internet Gateway and Route Table**
```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "route_assoc" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table.id
}
```

#### **Security Group for SSH Access**
```hcl
resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.myvpc.id
  name        = "ssh-access"
  description = "Allow SSH access"

  ingress {
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
    Name = "ssh-access-sg"
  }
}
```

#### **Key Pair**
```hcl
resource "aws_key_pair" "key_pair" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub") # Use your public key path
}
```

#### **Instances**
- **Controller Instance**
```hcl
resource "aws_instance" "controller" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  private_ip             = "10.0.1.10"

  user_data = base64encode(file("workspace/controller.sh"))

  tags = {
    Name = "Controller"
  }
}
```

- **Worker Instances**
```hcl
resource "aws_instance" "worker1" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  private_ip             = "10.0.1.11"

  tags = {
    Name = "Worker1"
  }
}

resource "aws_instance" "worker2" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  private_ip             = "10.0.1.12"

  tags = {
    Name = "Worker2"
  }
}
```

---

### **4. Validating Ansible Cluster**

1. **SSH into Controller:**
   ```bash
   ssh -i <private-key-path> ubuntu@<controller-public-ip>
   ```

2. **Verify Ansible Installation:**
   ```bash
   ansible --version
   ```

3. **Ping Managed Nodes:**
   Run the ping command:
   - make sure where inventory file is available 
   ```bash
   ansible all -i hosts -m ping
   ```

4. **Run Playbooks:**
   Clone repository if needed:
   ```bash
   git clone https://github.com/thej950/playbooks01.git
   ```
   Execute a playbook:
   ```bash
   ansible-playbook playbook.yml -i hosts --check
   ```

---

### **5. Improvements**
- Use **Terraform modules** for better code reuse.
- Implement **output blocks** in Terraform to display key information such as public IPs.
- Use `remote-exec` to verify configurations post-deployment.

Let me know if you need further optimization or automation in any specific step!


### inventory file 
```bash
[controller]
10.0.1.10 ansible_user=ubuntu ansible_ssh_private_key_file=./sshkeys/terraform

[workers]
10.0.1.11 ansible_user=ubuntu ansible_ssh_private_key_file=./sshkeys/terraform
10.0.1.12 ansible_user=ubuntu ansible_ssh_private_key_file=./sshkeys/terraform
```

### Ansible Setup
1. Directory Structure
```bash
plaintext
Copy code
workspace/
├── controller.sh
├── sshkeys/
│   ├── terraform (private key)
│   ├── terraform.pub (public key)
└── inventory
```

