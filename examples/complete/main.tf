# data "aws_canonical_user_id" "current" {}

provider "aws" {
  access_key                  = "mock_access_key"
  region                      = "eu-west-1"
  s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true


  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    kms            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

locals {
  bucket_name = "s3-bucket-${random_pet.this.id}"
}

resource "random_pet" "this" {
  length = 2
}

resource "aws_kms_key" "objects" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

module "log_bucket" {
  source = "../../"

  bucket                         = "logs-${random_pet.this.id}"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  attach_elb_log_delivery_policy = true
}

module "s3_bucket" {
  source = "../../"

  bucket        = local.bucket_name
  # acl           = "private"
  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json

  tags = {
    Owner = "Anton"
  }

  versioning = {
    enabled = true
  }

  website = {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules = jsonencode([{
      Condition : {
        KeyPrefixEquals : "docs/"
      },
      Redirect : {
        ReplaceKeyPrefixWith : "documents/"
      }
    }])

  }

  logging = {
    target_bucket = module.log_bucket.this_s3_bucket_id
    target_prefix = "log/"
  }

  cors_rule = {
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://modules.tf", "https://terraform-aws-modules.modules.tf"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true
      prefix  = "log/"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
          }, {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 90
      }

      noncurrent_version_expiration = {
        days = 30
      }
    },
    {
      id                                     = "log1"
      enabled                                = true
      prefix                                 = "log1/"
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]

      noncurrent_version_expiration = {
        days = 300
      }
    },
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.objects.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode  = "COMPLIANCE"
        years = 5
      }
    }
  }

  grant = [
    {
      id          = "cda1c626820f0256b7b8c9939fb8c8b95d2cb448e46a56232e49195df360ec75"
      type        = "CanonicalUser"
      permissions = ["FULL_CONTROL"]
    },
    {
      type        = "Group"
      permissions = ["READ_ACP", "WRITE"]
      uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    }
  ]

  // S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
