

provider "aws" {
  access_key                  = "mock_access_key"
  region                      = var.region
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

data "aws_caller_identity" "current" {}

resource "random_pet" "this" {
  length = 2
}

module "s3_bucket" {
  source = "../../"

  bucket = var.bucket_name
  region = var.region
  acl    = "private"

  versioning = {
    enabled = true
  }

}

variable "bucket_name" {}
variable "region" {}
