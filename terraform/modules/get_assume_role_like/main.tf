terraform {
  required_version = ">= 1.9.3"
}

variable "role_arns" {
    type = list(string)
}

locals {
  transformed = [for arn in var.role_arns: 
    replace(
        replace(arn, ":role/", ":assumed-role/"),
        ":iam:",
        ":sts:"
        )
    ]
  # Since sessions can be anything, we add the wild card
  with_wildcard = [for arn in local.transformed: "${arn}/*"]
}

output "wildcard_arns" {
    value = local.with_wildcard
}