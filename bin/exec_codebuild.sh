#!/bin/bash

project_name=$1
source_version=$2

options=""
if [ "$source_version" != "" ]; then
  options+="--source-version $source_version"
fi
codebuild_id=$(aws codebuild start-build --project-name "$project_name" "$options" | tr -d "\n" | jq -r '.build.id')
echo "$project_name started.. id is $codebuild_id"
while true
do
  sleep 10s
  status=$(aws codebuild batch-get-builds --ids "$codebuild_id" | tr -d "\n" | jq -r '.builds[].buildStatus')
  echo "..status is $status."
  if [ "$status" != "IN_PROGRESS" ]; then
    if [ "$status" != "SUCCEEDED" ]; then
      echo "faild."
      exit 99
    fi
  echo "done."
  break
  fi
done
