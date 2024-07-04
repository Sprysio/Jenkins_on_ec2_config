# Create VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "jenkins_vpc"
  }
}

# Create Subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                      = aws_vpc.jenkins_vpc.id
  cidr_block                  = "10.0.1.0/24"
  map_public_ip_on_launch     = true  
  availability_zone           = "eu-north-1a"
  tags = {
    Name = "jenkins_subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = {
    Name = "jenkins_igw"
  }
}

# Create Route Table
resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
  tags = {
    Name = "jenkins_route_table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "jenkins_route_table_association" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

#Security group
resource "aws_security_group" "jenkins_sg"{
  name  = "jenkins_sg1"
  description   = "Allow inbound ports 22, 8080"
  vpc_id = aws_vpc.jenkins_vpc.id
  
  #Allow incoming TCP on port 22 from any IP
  ingress{
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow incoming TCP on port 8080 from any IP
  ingress{
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound
  egress{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#S3 bucket for Jenkins Artifacts
resource "aws_s3_bucket" "my-s3-bucket" {
  bucket = var.bucket
  tags = {
    Name  = "Jenkins-Server"
  }
}

#Making S3 private and not open to public
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.my-s3-bucket.id
  acl    = var.acl
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.my-s3-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

#Keypair for access to EC2
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

#IAM role
resource "aws_iam_role" "my-s3-jenkins-role" {
  name = "s3-jenkins_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" 
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#IAM policy
resource "aws_iam_policy" "s3-jenkins-policy" {
  name   = "s3-jenkins-rw-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReadWriteAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket}",
        "arn:aws:s3:::${var.bucket}/*"
      ]
    }
  ]
}
EOF
}

#Attach access
resource "aws_iam_role_policy_attachment" "s3-jenkins-access" {
  policy_arn = aws_iam_policy.s3-jenkins-policy.arn
  role       = aws_iam_role.my-s3-jenkins-role.name
}

#Instance profile
resource "aws_iam_instance_profile" "s3-jenkins-profile" {
  name = "s3-jenkins-profile"
  role = aws_iam_role.my-s3-jenkins-role.name
}

# Create EBS Volume
resource "aws_ebs_volume" "jenkins_volume" {
  availability_zone = "eu-north-1a"
  size              = 15  

  tags = {
    Name = "JenkinsRootVolume"
  }
}

#Create EC2
resource "aws_instance" "jenkins_ec2" {
  ami                  = var.ami_id                
  instance_type        = var.instance_type         
  subnet_id            = aws_subnet.jenkins_subnet.id
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.s3-jenkins-profile.name
  tags = {
    Name = "JenkinsEC2Instance"
  }
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_id   = aws_ebs_volume.jenkins_volume.id
  }

    provisioner "file" {
    source      = "setup_jenkins.yml"
    destination = "/home/ec2-user/setup_jenkins.yml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

   provisioner "remote-exec" {
    inline = [
      "sudo yum install ansible-core -y",
      "ansible-playbook -i 'localhost,' -c local /home/ec2-user/setup_jenkins.yml"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

output "instance_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}
