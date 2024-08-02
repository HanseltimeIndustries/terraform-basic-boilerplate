locals {
  common_values = yamldecode(file(find_in_parent_folders("common.yaml")))
}

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_terragrunt_dir()}/../../terraform//bootstrap"
}

inputs = {
  s3_backend_bucket_name = local.common_values.s3_backend_bucket
}