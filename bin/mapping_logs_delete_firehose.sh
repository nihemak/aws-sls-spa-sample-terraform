#!/bin/bash

api_stack=$1

prefix="/aws/lambda/$api_stack"
echo "${prefix}"

aws logs describe-log-groups \
  --log-group-name-prefix "${prefix}"| jq -r '.logGroups[].logGroupName' | while read -r log_group_name
do
  logs_args=(logs describe-subscription-filters --log-group-name "$log_group_name")
  log_group_name=$(aws "${logs_args[@]}" | tr -d "\n" | jq -r '.subscriptionFilters[].logGroupName')
  if [ "$log_group_name" != "" ]; then
    aws logs delete-subscription-filter \
      --log-group-name "$log_group_name" \
      --filter-name "logFilter"
  fi
done
