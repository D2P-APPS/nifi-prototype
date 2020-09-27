#
# I have no defaults so values are in the terraform.tfvars files. There is only one source of truth.
#
variable "aws_profile_name" {
  type        = string
}
variable "instance_type"        { 
  type        = string
}
variable "key_name"             {
  type        = string
}
variable "key_private_file" {
  description = "PEM file used to SSH into provisioned servers."
  type        = string
}
variable "key_public_file"      {
  type        = string
}
variable "region" {
  description = "The region Terraform deploys your instance"
  type        = string
}
variable "ssh_user" {
  description = "Account used for SSH (i.e. centos or ec2-user)"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "vpc_name" {
  type        = string
}
