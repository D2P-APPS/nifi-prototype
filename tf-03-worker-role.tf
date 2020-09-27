data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  name = "${var.vpc_name}-worker-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "worker" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ])
  role       = aws_iam_role.worker.id
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.vpc_name}-worker-instance-profile"
  role = aws_iam_role.worker.name
}
