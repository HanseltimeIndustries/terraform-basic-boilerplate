# Example Base Terraform IAC

This repo holds Terragrunt + Terraform IAC for standing up basic patterns
with CI/CD in AWS (and potentially in the future other cloud
providers).

## Bootstrap pattern

One of the big issues with terraform out of the box is that it needs to use a backend to store it's state
files.  If you do not want to add a dependency on terraform cloud, then you will need to set up an s3 bucket
and then appropriately manage different apply_roles that can access it.

Terragrunt does some of thw work for you, but does not supply sufficiently strict policies to the s3 bucket that
is created.  Because of this, we set up terragrunt to always have a bootstrap repo that will import the auto-created
`remote_backend` and then allow us to manage roles that should be the only ones capable of reaching this store.

# Getting started

## Tool Setup

There is a best effort shell script for debian/ubuntu at [setup-tools.sh](bin/setup-tools.sh)

## Linting

To lint, call tflint

