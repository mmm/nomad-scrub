
resource "aws_iam_role" "ec2_default" {
  name = "nomad_default_iam_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_default_profile" {
  name = "nomad-default-instance-profile"
  role = "${aws_iam_role.ec2_default.name}"
}

resource "aws_iam_policy" "nomad_bucket_policy" {
  name = "nomad-bucket-readwrite"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::nomad-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListObjects",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::nomad-*/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "nomad_instances_read_buckets" {
  name       = "nomad-instances-read-buckets"
  roles      = ["${aws_iam_role.ec2_default.name}"]
  policy_arn = "${aws_iam_policy.nomad_bucket_policy.arn}"
}
