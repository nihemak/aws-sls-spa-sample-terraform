variable "s3_bucket_artifact_store_id" {}
variable "resource_prefix" {}
variable "iam_role_pipeline_build_arn" {}
variable "codebuild_name_test" {}
variable "codebuild_name_staging" {}
variable "codebuild_name_staging_e2e" {}
variable "codebuild_name_production" {}
variable "codecommit_repository" {}
variable "approval_sns_topic_arn" {}

resource "aws_codepipeline" "service" {
  name     = "${var.resource_prefix}-web"
  role_arn = "${var.iam_role_pipeline_build_arn}"

  artifact_store {
    location = "${var.s3_bucket_artifact_store_id}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      owner    = "AWS"
      name     = "Source"
      provider = "CodeCommit"
      version  = 1

      configuration = {
        PollForSourceChanges = "false"
        RepositoryName       = "${var.codecommit_repository}"
        BranchName           = "master"
      }

      output_artifacts = ["MyApp"]
    }
  }

  stage {
    name = "Test"

    action {
      category = "Test"
      owner    = "AWS"
      name     = "CodeBuild-Test"
      provider = "CodeBuild"
      version  = 1

      configuration = {
        ProjectName = "${var.codebuild_name_test}"
      }

      input_artifacts = ["MyApp"]
    }
  }

  stage {
    name = "Build-Staging"

    action {
      category = "Test"
      owner    = "AWS"
      name     = "CodeBuild-Staging-E2E"
      provider = "CodeBuild"
      version  = 1

      configuration = {
        ProjectName = "${var.codebuild_name_staging_e2e}"
      }

      input_artifacts = ["MyApp"]
      run_order       = 1
    }

    action {
      category = "Build"
      owner    = "AWS"
      name     = "CodeBuild-Staging"
      provider = "CodeBuild"
      version  = 1

      configuration = {
        ProjectName = "${var.codebuild_name_staging}"
      }

      input_artifacts  = ["MyApp"]
      output_artifacts = ["MyAppBuild"]
      run_order        = 2
    }

    action {
      category = "Approval"
      owner    = "AWS"
      name     = "Approval"
      provider = "Manual"
      version  = 1

      configuration = {
        NotificationArn = "${var.approval_sns_topic_arn}"
      }

      run_order = 3
    }
  }

  stage {
    name = "Build-Production"

    action {
      category = "Build"
      owner    = "AWS"
      name     = "CodeBuild-Production"
      provider = "CodeBuild"
      version  = 1

      configuration = {
        ProjectName = "${var.codebuild_name_production}"
      }

      input_artifacts = ["MyApp"]
    }
  }
}

output "arn" {
  value = "${aws_codepipeline.service.arn}"
}
