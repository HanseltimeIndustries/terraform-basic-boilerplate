terraform {
  required_version = ">= 1.9.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Must deploy this first on first deploy
data "aws_iam_policy_document" "triage_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      ]

    principals {
      type        = "AWS"
      identifiers = [var.aws_account_id]
    }

    # In this scenario, we use tag attribute to denote - TODO update this
    # condition {
    #   test = "StringEquals"
    #   variable = "aws:RequestTag/tf_triage"
    #   values = [ "true" ]
    # }
  }
}

data "aws_iam_policy_document" "ci_apply_assume_policy" {
  // TODO: set up this document to deal with your specific CI/CD authentication scheme
  // This IS NOT a good policy since anyone in the account can assume it
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      ]

    principals {
      type        = "AWS"
      identifiers = [var.aws_account_id]
    }
  }
}

data "aws_iam_policy_document" "ci_plan_assume_policy" {
  // TODO: set up this document to deal with your specific CI/CD authentication scheme
  // This IS NOT a good policy since anyone in the account can assume it
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      ]

    principals {
      type        = "AWS"
      identifiers = [var.aws_account_id]
    }
  }
}

resource "aws_iam_role" "triage_user_role" {
  name         = "tf-triage-user-role"
  assume_role_policy = data.aws_iam_policy_document.triage_assume_policy.json
  // We don't need to add any more to this role since we only need to deploy backend right now
  // In the future, we could add policies for other backends, etc.
}

resource "aws_iam_role" "main_apply_role" {
  name         = "main-iac-apply-role"
  assume_role_policy = data.aws_iam_policy_document.ci_apply_assume_policy.json
  // TODO - if we were managing this as a central repo, we would attach policies that allow the rest of the
  // deployment as well
}

resource "aws_iam_role" "main_plan_role" {
  name         = "main-iac-plan-role"
  assume_role_policy = data.aws_iam_policy_document.ci_plan_assume_policy.json
  // TODO - if we were managing this as a central repo, we would attach policies that allow the rest of the
  // deployment as well
}
