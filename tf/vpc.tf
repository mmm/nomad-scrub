# Setup AWS to use us-east-1
provider "aws" {
  region     = "us-west-2"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

# Configure a VPC with a public and private subnet
module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"
  name   = "nomad-vpc"

  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway   = "true"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  azs = ["us-west-2a", "us-west-2b", "us-west-2c"]

  tags {
    "Terraform" = "true"
  }
}
