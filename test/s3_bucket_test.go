package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestS3Simple(t *testing.T) {
	t.Parallel()

	// awsRegion := "eu-west-1"
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/s3-simple",
		Upgrade:      true,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// bucketID := terraform.Output(t, terraformOptions, "this_s3_bucket_id")

	// actualStatus := aws.GetS3BucketVersioning(t, awsRegion, bucketID)
	// expectedStatus := "Enabled"
	// assert.Equal(t, expectedStatus, actualStatus)
}
