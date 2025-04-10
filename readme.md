### This project will setup ansible cluster with one controller and two worker machinens using terraform 
### **1. Pre-requisites**

#### **1.1 Install Required Tools**
Make sure the following tools are installed on your local machine:
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

#### **1.2 Clone the Repository**
Clone the repository containing the Terraform and Ansible setup:
```bash
git clone https://github.com/thej950/Ansible_TF.git
cd ansible_tf_work
```

#### **1.3 Configure AWS CLI**
- Create an AWS IAM user with `AdministratorAccess`.
- Generate and download the **Access Key ID** and **Secret Access Key**.
- Configure the AWS CLI:
  ```bash
  aws configure
  ```
  - Provide the following details:
    - **Access Key ID**: `XXXXXXXXX`
    - **Secret Access Key**: `XXXXXXXXXX`
    - **Region**: `us-east-1` (or your preferred region)
    - **Output Format**: `text`
---

### **2. Execute Terraform Commands**

Navigate to the Terraform working directory (if not already there):
```bash
cd ansible_tf_work
```

Run the following commands:

#### **2.1 Initialize Terraform**
```bash
terraform init
```
This sets up the necessary backend plugins and initializes the working directory.

#### **2.2 Plan Infrastructure**
```bash
terraform plan
```
This command generates an execution plan, showing the resources Terraform will create.

#### **2.3 Apply the Terraform Configuration**
```bash
terraform apply -auto-approve
```
This creates the infrastructure as defined in the Terraform configuration files.

#### **2.4 Destroy the Infrastructure (Optional)**
If you want to clean up the resources, run:
```bash
terraform destroy -auto-approve
```

---

### **3. Next Steps**

#### **3.1 Verify Infrastructure**
- Check that the resources (VPC, Subnet, EC2 instances, etc.) were created successfully in the AWS Management Console.
- Note down the public IP of the **controller instance** for SSH access.

#### **3.2 Connect to the Controller Instance**
Use SSH to connect to the **controller** instance:
```bash
ssh -i <path-to-private-key> ubuntu@<controller-public-ip>
```

#### **3.3 Configure and Test Ansible**
- Verify Ansible installation on the controller:
  ```bash
  ansible --version
  ```
- Test communication with the managed nodes:
  ```bash
  ansible all -i hosts -m ping
  ```

- Execute a playbook:
  ```bash
  ansible-playbook <playbook_name> -i <path_of_inventory_file>
  ```
  ```bash
  ansible-playbook playbook.yml -i hosts --check        
  ```

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



===
The configuration you provided appears to resemble **inventory file syntax**, not a valid `ansible.cfg` file format. In **`ansible.cfg`**, you cannot define hosts and private keys directly. Instead, the `ansible.cfg` file is used to configure Ansible behavior globally or for a specific project.

---

### **Correct Way to Define Hosts and Keys:**

1. **In Inventory File (Best Practice):**
   You should specify the hosts and SSH private key in an inventory file (e.g., `inventory.ini` or `inventory.yml`).

   **Example (INI Format):**
   ```ini
   [webservers]
   10.0.1.11 ansible_ssh_private_key_file=/home/ubuntu/workspace/sshkeys/terraform
   10.0.1.12 ansible_ssh_private_key_file=/home/ubuntu/workspace/sshkeys/terraform
   ```

   **Example (YAML Format):**
   ```yaml
   all:
     hosts:
       10.0.1.11:
         ansible_ssh_private_key_file: /home/ubuntu/workspace/sshkeys/terraform
       10.0.1.12:
         ansible_ssh_private_key_file: /home/ubuntu/workspace/sshkeys/terraform
   ```

2. **In `ansible.cfg`:**
   The `ansible.cfg` file can reference the inventory file and define general connection defaults.

   **Example:**
   ```ini
   [defaults]
   inventory = inventory.ini
   private_key_file = /home/ubuntu/workspace/sshkeys/terraform
   host_key_checking = False
   ```

   Alternatively, you can omit `private_key_file` from `ansible.cfg` and manage it in the inventory file as shown above.

---

### **Mistakes in Your Syntax:**
- The lines `10.0.1.11 ansible_ssh_private_key_file=...` are **not valid in `ansible.cfg`**. They belong in an inventory file.
- Ansible configuration files (`ansible.cfg`) do not list individual hosts.

---

### **Key Separation of Roles:**
- Use the **inventory file** for host-specific settings like private keys, hostnames, and ports.
- Use **`ansible.cfg`** for global configurations and defaults. 

