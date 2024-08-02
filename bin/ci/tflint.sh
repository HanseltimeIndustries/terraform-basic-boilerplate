#!/bin/bash -e

# Since terraform or tflint does not have recursive support for running tools, we
# have to make it up here.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

tfDirs=$(find ${SCRIPT_DIR}/../terraform/ -type f -name '*.tf' -exec dirname {} \; | sort -u)

for dir in $directories; do
  echo "Running tflint in $dir"
  (cd "$dir" && terragrunt plan)
done