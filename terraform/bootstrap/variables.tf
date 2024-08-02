variable "aws_region" {
  description = "The aws_region to deploy to"
  type        = string
}

variable "s3_backend_bucket_name" {
  description = "This is the bucket name that terragrunt created that we then manage"
  type        = string
}
