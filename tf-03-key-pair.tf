resource "aws_key_pair" "ssh" {
  public_key = file(var.key_public_file)
}
