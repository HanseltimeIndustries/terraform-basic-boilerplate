#!/bin/bash -e

###################################################
#
# Sets up tools on a linux system (may set them up
# on other systems in the future)
#
####################################################

ARCH=$(dpkg --print-architecture)
GRUNT_VERSION="v0.64.5"

set +e
tfVersion=$(terraform --version)
code=$?
set -e
if [ "$code" != "0" ]; then
    echo "Attempting to install terraform for debian/ubuntu..."
    # https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt-get install terraform
fi

set +e
tfVersion=$(tflint --version)
code=$?
set -e
if [ "$code" != "0" ]; then
    echo "Attempting to install tflint..."
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi


set +e
tgruntVersion=$(terragrunt --version)
code=$?
set -e
if [ "$code" != "0" ]; then
    echo "Attempt to install terragrunt..."
    wget https://github.com/gruntwork-io/terragrunt/releases/download/${GRUNT_VERSION}/terragrunt_linux_${ARCH}
    mkdir temp_terragrunt
    mv terragrunt_linux_${ARCH} temp_terragrunt/terragrunt
    chmod u+x terragrunt
    sudo mv temp_terragrunt/terragrunt /usr/local/bin/terragrunt
    rm -rf temp_terragrunt
fi