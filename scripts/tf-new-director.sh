#!/usr/bin/env bash

terraform() {
  local DOCKER_COMMON="--rm -u $UID -v $HOME:$HOME -e HOME -e USER=$USER -e USERNAME=$USER -i"
  docker run $DOCKER_COMMON -w $PWD -t hashicorp/terraform:0.11.14 $@
}

rm terraform.tfstate*

terraform init
terraform plan -out=plan
terraform apply plan

echo Add these nameservers for environment
terraform output env_dns_zone_name_servers
