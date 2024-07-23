// S3 Bucket for backing state files
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

// TODO: evaluate this later
resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  acl = "private"
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "OnlyTfStateRole"
        Effect    = "Allow"
        Principal = "${aws_iam_role.tf_deploy_role.arn}"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })
}


// Bootstrap roles
data "aws_iam_policy" "AdministratorAccess" {
    arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "state_policy" {
    name = "tf-state-policy"

    policy = jsonencode({
        Version = "2012-20-17",
        Statement = [
            {
                Effect = "Allow"
                Action = [
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:CreateBucket"
                ]
                Resource = [
                    "${aws_s3_bucket.s3_bucket.arn}/*",
                ]
            },
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:GetObject" 
                ]
                // TODO - we can parameterize this later if we do multiple tf
                // state backends for smaller distributed infra apps
                Resource = [
                    "${aws_s3_bucket.s3_bucket.arn}/*",
                ]
            },
            // TODO - Setting up Dynamodb for distributed atomicity
            # {
            #     Effect = "Allow"
            #     Action = [
            #         "dynamodb:PutItem",
            #         "dynamodb:GetItem",
            #         "dynamodb:DescribeTable",
            #         "dynamodb:DeleteItem",
            #         "dynamodb:CreateTable" 
            #     ]
            #     Resource = [ "TBD" ]
            # }
        ]
    })
}

resource "iam_role" "tf_apply_role" {
    name = "tf-apply-role"
    managed_policy_arns = [
        aws_iam_policy.state_policy.arn,
        aws_iam_policy.AdministratorAccess.arn,
    ]
}