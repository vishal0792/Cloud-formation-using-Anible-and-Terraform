# Declaring the Cloud Service To be used and declaring a default region
provider "aws" {
  region = var.region
}

# Creation of Virtual Private Cloud
resource "aws_vpc" "group1_vpc" {
  cidr_block           = var.vpc_cidr   # 10.10.0.0/20
  enable_dns_hostnames = true

  tags = {
    Name = "group1_vpc-vpc"
  }
}

# Creating an Internet Gateway to provide internet connectivity to the VPC
resource "aws_internet_gateway" "group1_igw" {
  vpc_id = aws_vpc.group1_vpc.id

  tags = {
    Name = "group1_igw"
  }
}

# Creating 2 public and 2 Private Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.group1_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, 0) # 10.10.0.0/20 would become 10.10.0.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "PUB_SUB_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.group1_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, 1)  # 10.10.0.0/20 would become 10.10.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "PUB_SUB_b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.group1_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, 2) # 10.10.0.0/20 would become 10.10.2.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "PRI_SUB_-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.group1_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, 3) # 10.10.0.0/20 would become 10.10.3.0/24
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "PRI_SUB_-b"
  }
}

# Creating an Elastic IPs for NAT Gateways
resource "aws_eip" "NGW_A" {
  vpc = true
}

resource "aws_eip" "NGW_B" {
  vpc = true
}

# Creating the NAT Gateways
resource "aws_nat_gateway" "ngw_a" {
  allocation_id = aws_eip.NGW_A.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-gw-a"
  }
}

resource "aws_nat_gateway" "ngw_b" {
  allocation_id = aws_eip.NGW_B.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "nat-gw-b"
  }
}

# Creation of Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.group1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.group1_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.group1_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_a.id
  }

  tags = {
    Name = "private-rt-a"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.group1_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_b.id
  }

  tags = {
    Name = "private-rt-b"
  }
}

# Route Table Subnet Assoiation
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# Creating security_groups
resource "aws_security_group" "public" {
  name        = "public sg"
  description = "SG for Public Instances"
  vpc_id      = aws_vpc.group1_vpc.id


  ingress {
    description = "For SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_location}/32"]
  }

  ingress {
    description = "For HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_location}/32"]
  }

  ingress {
    description = "For Apache"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_location}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group" "private" {
  name        = "private sg"
  description = "SG for Private instances"
  vpc_id      = aws_vpc.group1_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.group1_vpc.cidr_block]
  }

  ingress {
    description = "For NewsAPI"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.group1_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb sg"
  description = "SG For ALB"
  vpc_id      = aws_vpc.group1_vpc.id

  ingress {
    description = "For Apache"
    from_port   = 8090
    to_port     = 8090
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
    Name = "alb-sg"
  }
}

# Specification for EC2 Instances
resource "aws_instance" "bastion" {
  ami                    = var.ec2_image_ids[var.region]
  instance_type          = var.ec2_instance_type
  key_name               = var.private_key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.public.id]

  tags = {
    Name = "Bastion-Host"
  }
}

resource "aws_instance" "latest_news_api_a" {
  ami                         = var.ec2_image_ids[var.region]
  instance_type               = var.ec2_instance_type
  key_name                    = var.private_key_name
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  associate_public_ip_address = false

  tags = {
    Name = "News-API-AZ-A"
  }

  depends_on = [aws_instance.bastion]

  # Initialize Server
  provisioner "remote-exec" {
    inline = ["echo 'Server Initialization ...'"]

    connection {
      type        = "ssh"
      agent       = false
      host        = self.private_ip
      user        = "ec2-user"
      private_key = file(var.private_key_file_path)

      bastion_host        = aws_instance.bastion.public_ip
      bastion_private_key = file(var.private_key_file_path)
    }
  }

  provisioner "local-exec" {
    command = ansible-playbook -i '${self.private_ip},' --ssh-common-args ' -o ProxyCommand="ssh -A  -q -W %h:%p ec2-user@${aws_instance.bastion.public_ip} -i ${var.private_key_file_path}"' -u ec2-user --private-key ${var.private_key_file_path} ../ansible/backend.yml

  }
}

resource "aws_instance" "latest_news_api_b" {
  ami                         = var.ec2_image_ids[var.region]
  instance_type               = var.ec2_instance_type
  key_name                    = var.private_key_name
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  associate_public_ip_address = false

  tags = {
    Name = "News-API-AZ-B"
  }

  depends_on = [aws_instance.bastion]

  # Initialize Server
  provisioner "remote-exec" {
    inline = ["echo 'Server Initialization ...'"]

    connection {
      type        = "ssh"
      agent       = false
      host        = self.private_ip
      user        = "ec2-user"
      private_key = file(var.private_key_file_path)

      bastion_host        = aws_instance.bastion.public_ip
      bastion_private_key = file(var.private_key_file_path)
    }
  }

  provisioner "local-exec" {
    command = ansible-playbook -i '${self.private_ip},' --ssh-common-args ' -o ProxyCommand="ssh -A -q -W %h:%p  ec2-user@${aws_instance.bastion.public_ip} -i ${var.private_key_file_path}"' -u ec2-user --private-key ${var.private_key_file_path} ../ansible/backend.yml
	  
  }
}

resource "aws_instance" "latest_news_website" {
  ami                    = var.ec2_image_ids[var.region]
  instance_type          = var.ec2_instance_type
  key_name               = var.private_key_name
  subnet_id              = aws_subnet.public_b.id
  vpc_security_group_ids = [aws_security_group.public.id]

  # To Ensure Dependency on ALB
  depends_on = [aws_lb.latest_news_api]

  tags = {
    Name = "News-Website"
  }

  # Initializing Server
  provisioner "remote-exec" {
    inline = ["echo 'Server Initialization ...'"]

    connection {
      type        = "ssh"
      agent       = false
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file(var.private_key_file_path)
    }
  }

  provisioner "local-exec" {
    command = ansible-playbook -i '${self.public_ip},' -u ec2-user --private-key ${var.private_key_file_path} --extra-vars "host=${aws_lb.latest_news_api.dns_name}" ../ansible/frontend.yml
  }
}

# Creating ALB
resource "aws_lb" "latest_news_api" {
  name               = "latest-news-api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "news-api-alb"
  }
}

# Creation of Target Group
resource "aws_lb_target_group" "latest_news_api" {
  name     = "latest-news-api-lb-tg"
  port     = 8090
  protocol = "HTTP"
  vpc_id   = aws_vpc.group1_vpc.id

  health_check {
    interval            = 10
    path                = "/actuator/health"
    port                = 8090
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  target_type = "instance"


  tags = {
    Name = "news-api-target-group"
  }
}

# adding listener to ALB
resource "aws_lb_listener" "latest_news_api" {
  load_balancer_arn = aws_lb.latest_news_api.arn
  port              = "8090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.latest_news_api.arn
  }
}

# ALB-TG Association
resource "aws_lb_target_group_attachment" "target_a" {
  target_group_arn = aws_lb_target_group.latest_news_api.arn
  target_id        = aws_instance.latest_news_api_a.id
  port             = 8090
}

resource "aws_lb_target_group_attachment" "target_b" {
  target_group_arn = aws_lb_target_group.latest_news_api.arn
  target_id        = aws_instance.latest_news_api_b.id
  port             = 8090
}
