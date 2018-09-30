#!/bin/bash

TF_VERSION=$1

curl -s -qL -o /usr/bin/jq https://stedolan.github.io/jq/download/linux64/jq
chmod +x /usr/bin/jq
curl -s -qL -o terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip -o terraform.zip
sudo mv terraform /bin
rm terraform.zip
