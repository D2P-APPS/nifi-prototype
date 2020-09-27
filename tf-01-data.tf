
# In case the default VPC is needed, here it is.
data "aws_vpc" "default_vpc" {
  tags = { "Default" = "true" }
}

data "aws_ami" "worker" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

data "aws_availability_zones" "available" {
    state = "available"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
