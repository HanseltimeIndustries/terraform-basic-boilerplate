#!/bin/bash -e

# This script should be sourced onto your shell.  It will run and apply sts assume role onto your shell

ROLE=$1
ACCOUNT=$2

# If no explicit account, then get the account from the curren role
if [ "$ACCOUNT" == "" ]; then
    ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account')
fi

OUT=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT:role/$ROLE --role-session-name aaa);
export AWS_ACCESS_KEY_ID=$(echo $OUT | jq -r '.Credentials''.AccessKeyId');
export AWS_SECRET_ACCESS_KEY=$(echo $OUT | jq -r '.Credentials''.SecretAccessKey');
export AWS_SESSION_TOKEN=$(echo $OUT | jq -r '.Credentials''.SessionToken');