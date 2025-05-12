# Jenkins on EC2 Configuration

This project automates the deployment of a Jenkins server on an AWS EC2 instance using Terraform and Ansible. It sets up the necessary AWS infrastructure, configures Jenkins, and ensures the server is ready for use.

## Features

- **AWS Infrastructure Setup**:
  - Creates a VPC, Subnet, Internet Gateway, and Route Table.
  - Configures a Security Group to allow SSH (port 22) and Jenkins (port 8080) access.
  - Sets up an S3 bucket for Jenkins artifacts with proper access controls.
  - Creates an IAM role and policy for S3 access.

- **EC2 Instance Configuration**:
  - Launches an EC2 instance with the specified AMI and instance type.
  - Attaches the IAM role for S3 access.
  - Configures the instance using Ansible to install and start Jenkins.

- **Automation**:
  - Uses Terraform for infrastructure provisioning.
  - Uses Ansible for Jenkins setup and configuration.

## Prerequisites

- Terraform installed on your local machine.
- Ansible installed on your local machine.
- AWS CLI configured with appropriate credentials.
- A valid SSH key pair (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`) for EC2 access.

## Usage

1. Initialize Terraform:
```
terraform init
```
2. Review and Apply Terraform Configuration:
```
terraform apply
```
Confirm the changes when prompted. Terraform will output the public IP of the EC2 instance.

4. Access Jenkins:

Open a browser and navigate to `http://<instance_ip>:8080`(replace `<instance_ip>` with the output from Terraform).
Follow the Jenkins setup instructions.

## File Structure
- **variables.tf**: Defines Terraform variables for AWS region, AMI ID, instance type, etc.
- **providers.tf**: Configures the AWS provider for Terraform.
- **main.tf**: Contains the main Terraform configuration for AWS resources.
- **setup_jenkins.yml**: Ansible playbook to install and configure Jenkins on the EC2 instance.
## Outputs
- **instance_ip**: The public IP address of the Jenkins EC2 instance.
## License
This project is licensed under the MIT License.