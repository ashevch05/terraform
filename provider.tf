provider "aws" {
  alias                      = "localstack"
  region                     = "us-east-1"

  skip_credentials_validation = true
  skip_requesting_account_id = true
  skip_region_validation = true
  s3_use_path_style = true

  access_key = "test"
  secret_key = "test"
  
  endpoints {
    s3             = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    sns            = "http://localhost:4566"
    iam            = "http://localhost:4566"
  }
}
