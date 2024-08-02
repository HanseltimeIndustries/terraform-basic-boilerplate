locals {
  common_values = yamldecode(file(find_in_parent_folders("common.yaml")))
}

remote_state {
  backend = "s3"
  config = {
    bucket = local.common_values.s3_backend_bucket
    key    = "main_repo/${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
  }
}

inputs = {
  aws_region  = local.common_values.aws_region
  bucket_name = local.common_values.s3_backend_bucket
}