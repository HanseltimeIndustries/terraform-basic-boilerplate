terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.9.3"
  backend "s3" {}
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# This imports the auto-generated terragrunt s3 bucket for management after
#  Important - we tighten up security on the bucket as a part of this management
import {
  to = aws_s3_bucket.tf_state_s3
  id = var.s3_backend_bucket_name
}

module "tf_s3_state_roles" {
  source = "../modules/bootstrap_roles"

  aws_account_id = data.aws_caller_identity.current.account_id
}

module "tf_assumed_role_arns" {
  source = "../modules/get_assume_role_like"

  role_arns = concat([for backend in module.tf_s3_state_roles.s3_state_backends : backend.apply_role.arn],
    [for backend in module.tf_s3_state_roles.s3_state_backends : backend.plan_role.arn],
    [
      module.tf_s3_state_roles.triage_user_role.arn,
      module.tf_s3_state_roles.s3_state_management_role.arn,
  ], )
}


resource "aws_s3_bucket" "tf_state_s3" {
  bucket = var.s3_backend_bucket_name
}

resource "aws_s3_bucket_versioning" "tf_state_s3" {
  bucket = var.s3_backend_bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}

// Apply a strict policy that only allows the given ARNs access
data "aws_iam_policy_document" "bucket_restrict_policy" {
  // Allow read-only role to its particular state files
  dynamic "statement" {
    for_each = module.tf_s3_state_roles.s3_state_backends
    content {
      actions = [
        "s3:GetObject"
      ]
      resources = [
        # For now we just add all files - longer term it would be super locked down to just do specific files
        "${aws_s3_bucket.tf_state_s3.arn}/*",
      ]
      principals {
        type = "AWS"
        identifiers = [
          statement.value.plan_role.arn,
        ]
      }
    }
  }
  // Allow apply role for its particular state files
  dynamic "statement" {
    for_each = module.tf_s3_state_roles.s3_state_backends
    content {
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = [
        # For now we just add all files - longer term it would be super locked down to just do specific files
        "${aws_s3_bucket.tf_state_s3.arn}/*",
      ]
      principals {
        type = "AWS"
        identifiers = [
          statement.value.apply_role.arn
        ]
      }
    }
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn
    ]
    principals {
      type = "AWS"
      identifiers = concat(
        [for backend in module.tf_s3_state_roles.s3_state_backends : backend.apply_role.arn],
        [for backend in module.tf_s3_state_roles.s3_state_backends : backend.plan_role.arn]
      )
    }
  }
  // Allow the triage user role and self-managing role full access (minus delete) (since it has to self-manage)
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn,
      "${aws_s3_bucket.tf_state_s3.arn}/*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        module.tf_s3_state_roles.triage_user_role.arn,
        module.tf_s3_state_roles.s3_state_management_role.arn,
      ]
    }
  }

  // Lock down this bucket for all unknown principals
  statement {
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn,
      "${aws_s3_bucket.tf_state_s3.arn}/*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id
      ]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values = concat(
        // Explicit roles
        [for backend in module.tf_s3_state_roles.s3_state_backends : backend.apply_role.arn],
        [for backend in module.tf_s3_state_roles.s3_state_backends : backend.plan_role.arn],
        [
          module.tf_s3_state_roles.triage_user_role.arn,
          module.tf_s3_state_roles.s3_state_management_role.arn,
        ],
        module.tf_assumed_role_arns.wildcard_arns,
      )
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  policy = data.aws_iam_policy_document.bucket_restrict_policy.json
  bucket = aws_s3_bucket.tf_state_s3.id

  # Apply this policy AFTER the aws roles have been provisioned that can interact with them
  depends_on = [
    aws_iam_role_policy_attachment.tf_state_admin_policy_self_manage,
    aws_iam_role_policy_attachment.tf_state_admin_policy_triage,
  ]
}


// Attach policies to the underlying roles
// TODO - for more security, it would be great to just limit to specific state files by having a per-file policy
//        but that is a lot given terraform's limitations
data "aws_iam_policy_document" "plan_policy" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      # For now we just add all files - longer term it would be super locked down to just do specific files
      "${aws_s3_bucket.tf_state_s3.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "plan_policy" {
  count = length(module.tf_s3_state_roles.s3_state_backends)

  name   = "${module.tf_s3_state_roles.s3_state_backends[count.index].plan_role.name}TfPlan"
  policy = data.aws_iam_policy_document.plan_policy.json
}

resource "aws_iam_role_policy_attachment" "plan_policy" {
  count = length(module.tf_s3_state_roles.s3_state_backends)

  role       = module.tf_s3_state_roles.s3_state_backends[count.index].plan_role.name
  policy_arn = aws_iam_policy.plan_policy[count.index].arn
}

// Apply roles
data "aws_iam_policy_document" "apply_policy" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PubObject"
    ]
    resources = [
      # For now we just add all files - longer term it would be super locked down to just do specific files
      "${aws_s3_bucket.tf_state_s3.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "apply_policy" {
  count = length(module.tf_s3_state_roles.s3_state_backends)

  name   = "${module.tf_s3_state_roles.s3_state_backends[count.index].apply_role.name}TfApply"
  policy = data.aws_iam_policy_document.apply_policy.json
}

resource "aws_iam_role_policy_attachment" "apply_policy" {
  count = length(module.tf_s3_state_roles.s3_state_backends)

  role       = module.tf_s3_state_roles.s3_state_backends[count.index].apply_role.name
  policy_arn = aws_iam_policy.apply_policy[count.index].arn
}

// Triage/Full Manage Roles
data "aws_iam_policy_document" "tf_state_admin_policy" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.tf_state_s3.arn,
      "${aws_s3_bucket.tf_state_s3.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "tf_state_admin_policy" {
  name   = "${aws_s3_bucket.tf_state_s3.bucket}Admin"
  policy = data.aws_iam_policy_document.tf_state_admin_policy.json
}

resource "aws_iam_role_policy_attachment" "tf_state_admin_policy_triage" {
  role       = module.tf_s3_state_roles.triage_user_role.name
  policy_arn = aws_iam_policy.tf_state_admin_policy.arn
}

resource "aws_iam_role_policy_attachment" "tf_state_admin_policy_self_manage" {
  role       = module.tf_s3_state_roles.s3_state_management_role.name
  policy_arn = aws_iam_policy.tf_state_admin_policy.arn
}

// Self management implies that we also have to be able to updated iam roles
data "aws_iam_policy_document" "bootstrap_admin_policy" {
  statement {
    actions = [
      "iam:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tf_state_admin_policy_self_manage_roles" {
  name   = "${aws_s3_bucket.tf_state_s3.bucket}RoleAdmin"
  policy = data.aws_iam_policy_document.bootstrap_admin_policy.json
}

resource "aws_iam_role_policy_attachment" "tf_state_admin_policy_self_manage_roles" {
  role       = module.tf_s3_state_roles.s3_state_management_role.name
  policy_arn = aws_iam_policy.tf_state_admin_policy_self_manage_roles.arn
}
