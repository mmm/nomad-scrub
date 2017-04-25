
# AWS requires an access key and secret
variable "aws_access_key" {}
variable "aws_secret_key" {}

# Control the number of Nomad workers
variable "client_count" {
  default = "1"
}
