provider "aws" {
  access_key                  = "mock_access_key"
  region                      = var.region
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

resource "random_pet" "this" {
  length = 2
}

module "s3_bucket" {
  source = "../../"

  bucket = var.bucket_name
  region = var.region

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

  versioning = {
    enabled = true
  }

}

variable "bucket_name" {}
variable "region" {}
