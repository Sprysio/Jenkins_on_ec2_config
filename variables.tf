variable "aws_region" {
  default = "eu-north-1"
  type    = string
}

variable "ami_id" {
  default = "ami-052387465d846f3fc"
  type    = string
}

variable "instance_type" {
  default = "t3.micro"
  type    = string
}

variable "key_name" {
  default = "ec2-keypair"
  type    = string
}

variable "bucket" {
  default = "jenkins-s3-bucket-inzynierka-op-rol"
  type    = string
}

variable "acl" {
  default = "private"
  type    = string
}