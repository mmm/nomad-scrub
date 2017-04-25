# Query for the latest AMI of Ubuntu 14.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Register our new key pair using the public key
resource "aws_key_pair" "nomad-key" {
  key_name   = "nomad-key"
  public_key = "${file("nomad-key.pem.pub")}"
}

# Create a security group that allows all inbound traffic
# used for the Nomad servers in the public subnet
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a nomad server in the public subnet, this also acts
# as our bastion host into the rest of the cluster
resource "aws_instance" "server" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  tags {
    Name = "Nomad Server"
  }

  subnet_id                   = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = "true"
  key_name                    = "${aws_key_pair.nomad-key.key_name}"
  vpc_security_group_ids      = ["${module.vpc.default_security_group_id}", "${aws_security_group.allow_all.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_default_profile.id}"

  connection {
    user        = "ubuntu"
    private_key = "${file("nomad-key.pem")}"
  }

  provisioner "file" {
    source      = "../bin/provision.sh"
    destination = "/tmp/provision.sh"
  }

  provisioner "file" {
    source      = "../nomad/mmm.nomad"
    destination = "/tmp/mmm.nomad"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh server ${aws_instance.server.private_ip}",
    ]
  }
}

# Create any number of nomad clients in the private subnet. They are
# provisioned using the nomad server as a bastion host.
resource "aws_instance" "client" {
  count         = "${var.client_count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  tags {
    Name = "Nomad Client"
  }

  subnet_id              = "${module.vpc.private_subnets[0]}"
  key_name               = "${aws_key_pair.nomad-key.key_name}"
  vpc_security_group_ids = ["${module.vpc.default_security_group_id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_default_profile.id}"

  connection {
    bastion_host = "${aws_instance.server.public_ip}"
    user         = "ubuntu"
    private_key  = "${file("nomad-key.pem")}"
  }

  provisioner "file" {
    source      = "../bin/nomad-exec-script.sh"
    destination = "/tmp/nomad-exec-script.sh"
  }

  provisioner "file" {
    source      = "../bin/provision.sh"
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nomad-exec-script.sh",
      "chmod +x /tmp/provision.sh",
      "sudo mv /tmp/nomad-exec-script.sh /usr/bin/nomad-exec-script.sh",
      "sudo /tmp/provision.sh client ${aws_instance.server.private_ip}",
    ]
  }
}

# Output the nomad server address to make it easier to setup Nomad
output "nomad_addr" {
  value = "http://${aws_instance.server.public_ip}:4646/"
}
output "server_ip" {
  value = "${aws_instance.server.public_ip}"
}
output "client_ip" {
  value = "${aws_instance.client.private_ip}"
}
