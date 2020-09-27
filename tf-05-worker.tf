#
# If subnet_id is not specified, then the default vpc is used.
# Make sure the subnet is inside the selected availability_zone.
#
# Disk volumes are specified as separate terraform resources
# so they can be managed if needed.
#

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.worker.id
  associate_public_ip_address = true
  availability_zone           = data.aws_availability_zones.available.names[0]
  depends_on                  = [aws_internet_gateway.ig]
  iam_instance_profile        = aws_iam_instance_profile.worker.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_subnet_a.id
  vpc_security_group_ids      = [
    aws_security_group.web.id,
    aws_security_group.ssh.id
  ]
  tags = {
    Name = "${var.vpc_name}-worker"
  }
  # Run a remote exec to wait for the server to be ready for SSH.
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.key_private_file)
    host        = self.public_ip
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = "100"
    delete_on_termination = true
  }
  #
  # Get the remote server ready for ansible playbooks. This runs as the centos user on
  # the remote server.
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 2; done",
      "sudo yum update -y",
      "sudo yum install -y python3",
      "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py",
      "sudo python3 get-pip.py",
      "sudo python3 -m pip install boto boto3"
    ]
  }
}

# ..######...########.##....##.########.########.....###....########.########.########.
# .##....##..##.......###...##.##.......##.....##...##.##......##....##.......##.....##
# .##........##.......####..##.##.......##.....##..##...##.....##....##.......##.....##
# .##...####.######...##.##.##.######...########..##.....##....##....######...##.....##
# .##....##..##.......##..####.##.......##...##...#########....##....##.......##.....##
# .##....##..##.......##...###.##.......##....##..##.....##....##....##.......##.....##
# ..######...########.##....##.########.##.....##.##.....##....##....########.########.

# .########.####.##.......########..######.
# .##........##..##.......##.......##....##
# .##........##..##.......##.......##......
# .######....##..##.......######....######.
# .##........##..##.......##.............##
# .##........##..##.......##.......##....##
# .##.......####.########.########..######.

resource "local_file" "inventory" {
  content = "[all]\n${aws_instance.worker.public_ip}"
  filename = "inventory"
  file_permission = "0644"
}
