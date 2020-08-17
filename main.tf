provider "aws" {
region = "ap-south-1"
profile = "Abhi"
}



resource "tls_private_key" "Abhikey0" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {    
  key_name   = "Abhikey0"
  public_key = "${tls_private_key.Abhikey0.public_key_openssh}"


  depends_on = [
    tls_private_key.Abhikey0
  ]
}

resource "local_file" "key-file" {
  content  = "${tls_private_key.Abhikey0.private_key_pem}"
  filename = "Abhikey0.pem"


  depends_on = [
    tls_private_key.Abhikey0
  ]
}



resource "aws_vpc" "abhivpc00" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "abhivpc00"
  }
}


resource "aws_security_group" "abhisg_wp" {
  name        = "abhisg_wp"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "${aws_vpc.abhivpc00.id}"


  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "abhisg_wp"
  }
}



resource "aws_security_group" "abhisg_bastionhost" {
  name        = "abhisg_bastionhost"
  description = "ssh_bh"
  vpc_id      = "${aws_vpc.abhivpc00.id}"


  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "abhisg_bastionhost"
  }
}


resource "aws_security_group" "abhisg_mysql" {
  name        = "abhisg_mysql"
  description = "mysql"
  vpc_id      = "${aws_vpc.abhivpc00.id}"


  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ "${aws_security_group.abhisg_bastionhost.id}" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "abhisg_mysql"
  }
}       


resource "aws_subnet" "abhisubnet_public" {
  vpc_id            = "${aws_vpc.abhivpc00.id}"
  availability_zone = "ap-south-1a"
  cidr_block        = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "abhisubnet_public"
  }
}

resource "aws_internet_gateway" "abhi_ig" {
  vpc_id = "${aws_vpc.abhivpc00.id}"
  tags = {
    Name = "abhi_ig"
  }
}
resource "aws_route_table" "abhi_route" {
  vpc_id = "${aws_vpc.abhivpc00.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.abhi_ig.id}"
  }
  tags = {
    Name = "abhi_route"
  }
}

resource "aws_route_table_association" "abhinata" {
  subnet_id      = aws_subnet.abhisubnet_public.id
  route_table_id = aws_route_table.abhi_route.id
}




resource "aws_subnet" "abhisubnet_private" {
  vpc_id            = "${aws_vpc.abhivpc00.id}"
  availability_zone = "ap-south-1b"
  cidr_block        = "192.168.2.0/24"
  tags = {
    Name = "abhisubnet_private"
  }
}

resource "aws_eip" "elastic_ip" {
  vpc      = true
}


resource "aws_nat_gateway" "abhi_natgateway" {
  allocation_id = "${aws_eip.elastic_ip.id}"
  subnet_id     = "${aws_subnet.abhisubnet_public.id}"
  depends_on    = [ "aws_nat_gateway.abhi_natgateway" ]
}


resource "aws_route_table" "abhi_natgateway_route" {
  vpc_id = "${aws_vpc.abhivpc00.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.abhi_natgateway.id}"
  }
  tags = {
    Name = "abhi_natgateway_route"
  }
}
resource "aws_route_table_association" "abhnatb" {
  subnet_id      = aws_subnet.abhisubnet_private.id
  route_table_id = aws_route_table.abhi_natgateway_route.id
}




resource "aws_instance" "AbhiWp_Os" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = "${aws_subnet.abhisubnet_public.id}"
  vpc_security_group_ids = [ "${aws_security_group.abhisg_wp.id}" ]
  tags = {
    
    Name = "AbhiWp_Os"
    
  }
}



resource "aws_instance" "Abhi_BaTionHost" {
  ami           = "ami-0ebc1ac48dfd14136"  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = "${aws_subnet.abhisubnet_public.id}"
  vpc_security_group_ids = [ "${aws_security_group.abhisg_bastionhost.id}" ]
  tags = {
    
    Name = "Abhi_BastionHost"
  }
}


resource "aws_instance" "Abhi_MySql" {
  ami           = "ami-0b5bff6d9495eff69"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = "${aws_subnet.abhisubnet_private.id}"
  vpc_security_group_ids = [ "${aws_security_group.abhisg_mysql.id}" ]
  tags = {
    
    Name = "Abhi_MySql"
  }
}
