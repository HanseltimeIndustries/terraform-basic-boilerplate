#!/bin/bash -e

# This is meant to be run with source on the shell

if [ "$1" == "" ]; then
    echo "Must provide aws profile as first argument"
    exit 1
fi

aws sso login --profile $1

export AWS_PROFILE=$1