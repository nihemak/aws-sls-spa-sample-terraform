# AWS Serverless SPA(Single Page Application) Sample: Build infrastructure with Terraform

[![CircleCI](https://circleci.com/gh/nihemak/aws-sls-spa-sample-terraform/tree/master.svg?style=svg)](https://circleci.com/gh/nihemak/aws-sls-spa-sample-terraform/tree/master)

This is a sample to build infrastructure of AWS serverless SPA service with Terraform.
The repositories for sample of SPA services are [API](https://github.com/nihemak/aws-sls-spa-sample-api) and [Web](https://github.com/nihemak/aws-sls-spa-sample-web).

## Service Architecture

![Service Architecture](docs/service_architecture.png)

## Build Flow (Staging and Production)

CodeBuild of setup:

![Setup](docs/build_flow_setup.png)

CodeBuild of service:

![Service](docs/build_flow_service.png)

CodePipeline:

![CodePipeline](docs/build_flow_codepipeline.png)

## Getting Started

Migrate a Github repository to AWS CodeCommit.

* Create an AWS CodeCommit Repository
* Clone the Repository and Push to the AWS CodeCommit Repository

```bash
# spa infra repository...
$ git clone https://github.com/nihemak/aws-sls-spa-sample-terraform.git sample-spa-infra
$ cd sample-spa-infra
$ aws cloudformation validate-template \
    --template-body file://bootstrap/CodeStore.cfn.yml
$ aws cloudformation create-stack \
    --stack-name foobar-sample-spa-CodeStore \
    --template-body file://bootstrap/CodeStore.cfn.yml
$ git push ssh://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/foobar-sample-spa-infra --all
$ cd ..
# spa api repository...
$ git clone https://github.com/nihemak/aws-sls-spa-sample-api.git sample-spa-api
$ cd sample-spa-api
$ git push ssh://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/foobar-sample-spa-api --all
$ cd ..
# spa web repository...
$ git clone https://github.com/nihemak/aws-sls-spa-sample-web.git sample-spa-web
$ cd sample-spa-web
$ git push ssh://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/foobar-sample-spa-web --all
$ cd ..
```

### Environment: Development

* Create S3 bucket for Terraform state saving
* Create CodeBuild's service role for development
* Create CodeBuild for development

```bash
$ aws cloudformation validate-template \
    --template-body file://bootstrap/EnvDev.cfn.yml
$ aws cloudformation create-stack \
    --stack-name foobar-sample-spa-EnvDev \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters \
      ParameterKey=CodeCommitStackName,ParameterValue=foobar-sample-spa-CodeStore \
    --template-body file://bootstrap/EnvDev.cfn.yml
```

Build development.

Run CodeBuild to build infrastructure and api and web with Terraform:

```bash
$ CODEBUILD_ID=$(aws codebuild start-build --project-name foobar-sample-spa-dev --source-version master | tr -d "\n" | jq -r '.build.id')
$ echo "started.. id is ${CODEBUILD_ID}"
$ while true
do
  sleep 10s
  STATUS=$(aws codebuild batch-get-builds --ids "${CODEBUILD_ID}" | tr -d "\n" | jq -r '.builds[].buildStatus')
  echo "..status is ${STATUS}."
  if [ "${STATUS}" != "IN_PROGRESS" ]; then
    if [ "${STATUS}" != "SUCCEEDED" ]; then
      echo "faild."
    fi
    echo "done."
    break
  fi
done
```

To delete the environment, execute the following:

```bash
$ aws codebuild start-build --project-name foobar-sample-spa-setup-destroy-service-codebuild-01 --source-version <branch of infrastructure>
```

### Environment: Staging and Production

Setup Required for Build infrastructure with AWS CodeBuild.

Create an SNS topic for approval of AWS CodePipeline:

```bash
$ aws sns create-topic --name foobar-sample-spa-approval-topic
$ aws sns subscribe --topic-arn arn:aws:sns:ap-northeast-1:<account-id>:foobar-sample-spa-approval-topic \
                    --protocol email \
                    --notification-endpoint <your email>
# and confirm...
$ aws sns confirm-subscription --topic-arn arn:aws:sns:ap-northeast-1:<account-id>:foobar-sample-spa-approval-topic \
                               --token <token value>
```

* Create S3 bucket for Terraform state saving
* Create CodeBuild's service role for setup
* Create CodeBuild for setup

```bash
$ aws cloudformation validate-template \
    --template-body file://bootstrap/EnvStgPrd.cfn.yml
$ aws cloudformation create-stack \
    --stack-name foobar-sample-spa-EnvStgPrd \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters \
      ParameterKey=CodeCommitStackName,ParameterValue=foobar-sample-spa-CodeStore \
    --template-body file://bootstrap/EnvStgPrd.cfn.yml
```

Setup and Build infrastructure.

Run CodeBuild to build infrastructure with Terraform:

```bash
$ CODEBUILD_ID=$(aws codebuild start-build --project-name foobar-sample-spa-setup --source-version master | tr -d "\n" | jq -r '.build.id')
$ echo "started.. id is ${CODEBUILD_ID}"
$ while true
do
  sleep 10s
  STATUS=$(aws codebuild batch-get-builds --ids "${CODEBUILD_ID}" | tr -d "\n" | jq -r '.builds[].buildStatus')
  echo "..status is ${STATUS}."
  if [ "${STATUS}" != "IN_PROGRESS" ]; then
    if [ "${STATUS}" != "SUCCEEDED" ]; then
      echo "faild."
    fi
    echo "done."
    break
  fi
done
```
