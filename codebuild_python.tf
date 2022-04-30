resource "aws_iam_role" "python_build" {
  name = "python_build"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
)
}

resource "aws_iam_role_policy" "python_build" {
  role = aws_iam_role.python_build.name

  policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:GetParameters"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Resource": [
            "*"
        ],
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
    },
    {
        "Effect": "Allow",
        "Resource": [
            "*"
        ],
        "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
        ],
        "Resource": [
            "*"
        ]
    },
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": [
            "ssm:GetParameters"
        ],
        "Resource": [
            aws_ssm_parameter.account-id.arn,
            aws_ssm_parameter.dockerhub-token.arn,
            aws_ssm_parameter.dockerhub-user.arn,
            aws_ssm_parameter.region.arn,
            aws_ssm_parameter.image1.arn,
            aws_ssm_parameter.image2.arn,
            aws_ssm_parameter.image-tag.arn
        ]
    },
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": [
            "kms:Decrypt"
        ],
        "Resource": [
            "*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ],
        "Resource": "*"
    },
  ]
})
}

resource "aws_codebuild_project" "python_build" {
  name          = "python_build"
  description   = "python_build_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.python_build.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "DOCKERHUB_USER"
      value = "dockerhub-user"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "DOCKER_TOKEN"
      value = "dockerhub-token"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "region"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "account-id"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "IMAGE1_URI"
      value = "image1"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "image-tag"
      type  = "PARAMETER_STORE"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/tsuyoshi7777/test0701.git"
    git_clone_depth = 1
    buildspec       = "python_buildspec.yml"
  }

}
