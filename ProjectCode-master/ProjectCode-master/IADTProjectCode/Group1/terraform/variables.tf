# Specifyying Region for Infrastructue setup
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default region"
}

# List of Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Defining Cidr block for VPC
variable "vpc_cidr" {
  default     = "10.10.0.0/20"
  description = "VPC Cidr"
}

# For Configuring Subnet Ciders
variable "subnet_cidr_newbits" {
  type        = string
  default     = 4
  description = "Subnet Cider Configuration"
}

# User-Region Specific Private Key
variable "private_key_name" {
  type        = string
  description = "User-Region Specific Private Key"
}

# Path to AWS Private key
variable "private_key_file_path" {
  type        = string
  description = "Path to AWS Private key"
}

# Allowed IP for SSH into bastion host
variable "ssh_location" {
  type        = string
  description = "Allowed IP for SSH into bastion host"
}

# Properties for ec2  Instance
variable "ec2_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Properties for ec2  Instance"
}

# Ami Selection
variable "ec2_image_ids" {
  type        = map
  description = "Ami Selection"

  default = {
    us-east-1      = "ami-0c2b8ca1dad447f8a"
    # us-east-2      = "ami-0e01ce4ee18447327"
  }
}
