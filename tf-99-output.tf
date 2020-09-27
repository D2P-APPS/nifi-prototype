output "key_private_file" {
    value = var.key_private_file
}
output "public_subnet_a" {
    value = aws_subnet.public_subnet_a.id
}
output "ssh_user" {
    value = var.ssh_user
}
output "worker_instance_id" {
    value = aws_instance.worker.id
}
output "worker_instance" {
    value = {
        "ami_id": data.aws_ami.worker.id,
        "ami_name": data.aws_ami.worker.name,
        "id": aws_instance.worker.id,
        "name": data.aws_ami.worker.name
        "public_ip": aws_instance.worker.public_ip,
        "vpc_name": var.vpc_name
      }
}
output "vpc_id" {
    value = aws_vpc.vpc.id
}
output "vpc_name" {
    value = var.vpc_name
}
