variable "aws_region" {
  type    = "string"
  default = "eu-central-1"
}

variable "namespace" {
  type    = "string"
  default = "io-dab-egami"
}

# Configure the AWS provider
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_s3_bucket" "egami_bucket_originals" {
  bucket = "${var.namespace}-originals"
}

resource "aws_s3_bucket" "egami_bucket_cached" {
  bucket = "${var.namespace}-cached"
}

resource "aws_s3_bucket_notification" "egami_create_bucket_notification" {
  bucket = "${aws_s3_bucket.egami_bucket_originals.id}"

  topic {
    topic_arn     = "${aws_sns_topic.egami_create.arn}"
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }

  topic {
    topic_arn     = "${aws_sns_topic.egami_remove.arn}"
    events        = ["s3:ObjectRemoved:*"]
    filter_suffix = ".png"
  }
}

resource "aws_sns_topic" "egami_create" {
  name         = "${var.namespace}-create"
  display_name = "egami create notifications"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "sns:Publish"
      ],
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "${aws_s3_bucket.egami_bucket_originals.arn}"
        }
      },
      "Effect": "Allow",
      "Principal": "*",
      "Resource": "arn:aws:sns:*:*:${var.namespace}-create"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_sns_topic" "egami_remove" {
  name         = "${var.namespace}-remove"
  display_name = "egami remove notifications"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "sns:Publish"
      ],
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "${aws_s3_bucket.egami_bucket_originals.arn}"
        }
      },
      "Effect": "Allow",
      "Principal": "*",
      "Resource": "arn:aws:sns:*:*:${var.namespace}-remove"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}
