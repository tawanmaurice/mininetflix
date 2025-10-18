terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#################################
# Config
#################################
variable "region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

#################################
# Default VPC + Subnet + Windows AMI
#################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Latest Windows Server 2022 (English, Full) AMI
data "aws_ami" "win2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#################################
# Security Group (RDP)
#################################
resource "aws_security_group" "rdp_sg" {
  name        = "win-rdp-sg"
  description = "Allow RDP for Windows"
  vpc_id      = data.aws_vpc.default.id

  # ⚠️ Wide open for demo — restrict to your IP if possible
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "win-rdp-sg" }
}

#################################
# EC2 Windows (t3.large)
#################################
resource "aws_instance" "win" {
  ami                    = data.aws_ami.win2022.id
  instance_type          = "t3.large"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.rdp_sg.id]

  # 👇 Replace with the name of your existing AWS key pair
  key_name          = "tawan-win"
  get_password_data = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = { Name = "win-t3-large-rdp" }
}

#################################
# Outputs
#################################
output "instance_id" {
  value = aws_instance.win.id
}

output "public_ip" {
  value = aws_instance.win.public_ip
}

output "rdp_url" {
  value = "rdp://${aws_instance.win.public_ip}"
}
