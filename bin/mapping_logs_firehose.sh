#!/bin/bash

api_stack=$1
firehose_delivery_stream_arn=$2
iam_role_api_log_cloudwatchlogs_to_s3_policy_arn=$3

prefix="/aws/lambda/$api_stack"
echo "${prefix}"

aws logs describe-log-groups \
  --log-group-name-prefix "${prefix}"| jq -r '.logGroups[].logGroupName' | while read log_group_name
do
  aws logs put-subscription-filter \
    --log-group-name "$log_group_name" \
    --filter-name "logFilter" \
    --filter-pattern "" \
    --destination-arn "$firehose_delivery_stream_arn" \
    --role-arn "$iam_role_api_log_cloudwatchlogs_to_s3_policy_arn"
done
