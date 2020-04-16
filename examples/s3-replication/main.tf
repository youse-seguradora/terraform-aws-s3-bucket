
provider "aws" {
  access_key                  = "mock_access_key"
  region                      = var.origin_region
  s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true


  endpoints {
    apigateway     = "http://localstack-s3:4567"
    cloudformation = "http://localstack-s3:4581"
    cloudwatch     = "http://localstack-s3:4582"
    dynamodb       = "http://localstack-s3:4569"
    es             = "http://localstack-s3:4578"
    firehose       = "http://localstack-s3:4573"
    iam            = "http://localstack-s3:4593"
    kinesis        = "http://localstack-s3:4568"
    kms            = "http://localstack-s3:4599"
    lambda         = "http://localstack-s3:4574"
    route53        = "http://localstack-s3:4580"
    redshift       = "http://localstack-s3:4577"
    s3             = "http://localstack-s3:4572"
    secretsmanager = "http://localstack-s3:4584"
    ses            = "http://localstack-s3:4579"
    sns            = "http://localstack-s3:4575"
    sqs            = "http://localstack-s3:4576"
    ssm            = "http://localstack-s3:4583"
    stepfunctions  = "http://localstack-s3:4585"
    sts            = "http://localstack-s3:4592"
  }
}

provider "aws" {
  access_key                  = "mock_access_key"
  region                      = var.replica_region
  s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  alias                       = "replica"

  endpoints {
    apigateway     = "http://localstack-s3:4567"
    cloudformation = "http://localstack-s3:4581"
    cloudwatch     = "http://localstack-s3:4582"
    dynamodb       = "http://localstack-s3:4569"
    es             = "http://localstack-s3:4578"
    firehose       = "http://localstack-s3:4573"
    iam            = "http://localstack-s3:4593"
    kinesis        = "http://localstack-s3:4568"
    kms            = "http://localstack-s3:4599"
    lambda         = "http://localstack-s3:4574"
    route53        = "http://localstack-s3:4580"
    redshift       = "http://localstack-s3:4577"
    s3             = "http://localstack-s3:4572"
    secretsmanager = "http://localstack-s3:4584"
    ses            = "http://localstack-s3:4579"
    sns            = "http://localstack-s3:4575"
    sqs            = "http://localstack-s3:4576"
    ssm            = "http://localstack-s3:4583"
    stepfunctions  = "http://localstack-s3:4585"
    sts            = "http://localstack-s3:4592"
  }
}

data "aws_caller_identity" "current" {}

resource "random_pet" "this" {
  length = 2
}

resource "aws_kms_key" "replica" {
  provider = aws.replica

  description             = "S3 bucket replication KMS key"
  deletion_window_in_days = 7
}

module "replica_bucket" {
  source = "../../"

  providers = {
    aws = aws.replica
  }

  bucket = replica_bucket_name
  region = var.replica_region
  acl    = "private"

  versioning = {
    enabled = true
  }
}

module "s3_bucket" {
  source = "../../"

  bucket = origin_bucket_name
  region = var.origin_region
  acl    = "private"

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = aws_iam_role.replication.arn

    rules = [
      {
        id       = "foo"
        status   = "Enabled"
        priority = 10

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        filter = {
          prefix = "one"
          tags = {
            ReplicateMe = "Yes"
          }
        }

        destination = {
          bucket             = "arn:aws:s3:::${local.destination_bucket_name}"
          storage_class      = "STANDARD"
          replica_kms_key_id = aws_kms_key.replica.arn
          account_id         = data.aws_caller_identity.current.account_id
          access_control_translation = {
            owner = "Destination"
          }
        }
      },
      {
        id       = "bar"
        status   = "Enabled"
        priority = 20

        destination = {
          bucket        = "arn:aws:s3:::${local.destination_bucket_name}"
          storage_class = "STANDARD"
        }


        filter = {
          prefix = "two"
          tags = {
            ReplicateMe = "Yes"
          }
        }

      },

    ]
  }

}

variable "origin_bucket_name" {}
variable "replica_bucket_name" {}
variable "origin_region" {}
variable "replica_region" {}
