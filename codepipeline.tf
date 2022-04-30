resource "aws_codepipeline" "codepipeline" {
  name     = "codepipeline-sample"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
      location = aws_s3_bucket.codepipeline_bucket.bucket
      type     = "S3"
      }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = "tsuyoshi7777/test0701"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "nginx_build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["nginx_build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.nginx_build.name
      }
    }
    action {
      name             = "python_build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["python_build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.python_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["source_output", "nginx_build_output", "python_build_output"]
      version         = "1"
      region          = "ap-northeast-1"


      configuration = {
        ApplicationName                = aws_codedeploy_app.codedeploy.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.codedeploy_group.deployment_group_name
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "nginx_build_output"
        Image1ContainerName            = "IMAGE1_NAME"
        Image2ArtifactName             = "python_build_output"
        Image2ContainerName            = "IMAGE2_NAME"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "example" {
  name          = "example-connection"
  provider_type = "GitHub"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "test-role"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
)
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
  {
          "Action": [
              "iam:PassRole"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Condition": {
              "StringEqualsIfExists": {
                  "iam:PassedToService": [
                      "cloudformation.amazonaws.com",
                      "elasticbeanstalk.amazonaws.com",
                      "ec2.amazonaws.com",
                      "ecs-tasks.amazonaws.com"
                  ]
              }
          }
      },
      {
          "Action": [
              "codecommit:CancelUploadArchive",
              "codecommit:GetBranch",
              "codecommit:GetCommit",
              "codecommit:GetRepository",
              "codecommit:GetUploadArchiveStatus",
              "codecommit:UploadArchive"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "codedeploy:CreateDeployment",
              "codedeploy:GetApplication",
              "codedeploy:GetApplicationRevision",
              "codedeploy:GetDeployment",
              "codedeploy:GetDeploymentConfig",
              "codedeploy:RegisterApplicationRevision"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "codestar-connections:UseConnection"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "elasticbeanstalk:*",
              "ec2:*",
              "elasticloadbalancing:*",
              "autoscaling:*",
              "cloudwatch:*",
              "s3:*",
              "sns:*",
              "cloudformation:*",
              "rds:*",
              "sqs:*",
              "ecs:*"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "lambda:InvokeFunction",
              "lambda:ListFunctions"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "opsworks:CreateDeployment",
              "opsworks:DescribeApps",
              "opsworks:DescribeCommands",
              "opsworks:DescribeDeployments",
              "opsworks:DescribeInstances",
              "opsworks:DescribeStacks",
              "opsworks:UpdateApp",
              "opsworks:UpdateStack"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "cloudformation:CreateStack",
              "cloudformation:DeleteStack",
              "cloudformation:DescribeStacks",
              "cloudformation:UpdateStack",
              "cloudformation:CreateChangeSet",
              "cloudformation:DeleteChangeSet",
              "cloudformation:DescribeChangeSet",
              "cloudformation:ExecuteChangeSet",
              "cloudformation:SetStackPolicy",
              "cloudformation:ValidateTemplate"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "codebuild:BatchGetBuilds",
              "codebuild:StartBuild",
              "codebuild:BatchGetBuildBatches",
              "codebuild:StartBuildBatch"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Effect": "Allow",
          "Action": [
              "devicefarm:ListProjects",
              "devicefarm:ListDevicePools",
              "devicefarm:GetRun",
              "devicefarm:GetUpload",
              "devicefarm:CreateUpload",
              "devicefarm:ScheduleRun"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "servicecatalog:ListProvisioningArtifacts",
              "servicecatalog:CreateProvisioningArtifact",
              "servicecatalog:DescribeProvisioningArtifact",
              "servicecatalog:DeleteProvisioningArtifact",
              "servicecatalog:UpdateProduct"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "cloudformation:ValidateTemplate"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ecr:DescribeImages"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "states:DescribeExecution",
              "states:DescribeStateMachine",
              "states:StartExecution"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "appconfig:StartDeployment",
              "appconfig:StopDeployment",
              "appconfig:GetDeployment"
          ],
          "Resource": "*"
      }
  ],
}
)
}
