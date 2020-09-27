provider "aws" {
  region  = var.region
  profile = var.aws_profile_name
  version    = "~> 3.4"
}

# Unique id to reference all other resouces under this template (useful for tags)
resource "random_string" "cluster_id" {
  length = 4
  lower = false
  number = false
  special = false
}
