variable aws_access_key {}
variable aws_secret_key {}
variable dockerhub-token {}
variable github_personal_access_token {}

terraform {
  required_version = "~> 1.0.0"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "ap-northeast-1"
}

#######################################
# ECR
#######################################

# ecr_nginx
resource "aws_ecr_repository" "ecr_nginx" {
  name                 = "nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "ecr_nginx_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t nginx -f nginx/ecs_Dockerfile ."
  }

  provisioner "local-exec" {
    command = "docker tag nginx:latest 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest"
  }

  provisioner "local-exec" {
    command = "docker push 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest"
  }
}

# ecr_python
resource "aws_ecr_repository" "ecr_python" {
  name                 = "python"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "null_resource" "ecr_python_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t python -f python/ecs_Dockerfile ."
  }

  provisioner "local-exec" {
    command = "docker tag python:latest 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/python:latest"
  }

  provisioner "local-exec" {
    command = "docker push 823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/python:latest"
  }
}


#######################################
# VPC
#######################################
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "sample"
  }
}

# Subnet
resource "aws_subnet" "public_0" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "public_1" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "ap-northeast-1c"
}

resource "aws_subnet" "private_0" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "ap-northeast-1c"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# route table association
resource "aws_route_table_association" "public_0" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_0.id
}

resource "aws_route_table_association" "public_1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_1.id
}

# security group
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.example.id
}

resource "aws_security_group_rule" "ingress_example_http" {
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_example_https" {
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_example" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.example.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

#######################################
# Route53
#######################################
data "aws_route53_zone" "example" {
  name = "takezawatsuyoshi7777.com"
}

## ALBのDNSレコードの定義
resource "aws_route53_record" "example" {
  name    = data.aws_route53_zone.example.name
  zone_id = data.aws_route53_zone.example.id
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_alb.example.dns_name
    zone_id                = aws_alb.example.zone_id
  }
}

#######################################
# ACM(SSL証明書の作成)
#######################################
resource "aws_acm_certificate" "example" {
  domain_name               = data.aws_route53_zone.example.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 検証用DNSレコードの作成
resource "aws_route53_record" "example-test" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id = data.aws_route53_zone.example.id
  ttl     = 60
}

# DNSレコードの検証
resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example-test : record.fqdn]
}

#########################################################################
# ALB
#########################################################################

# ALB本体
resource "aws_alb" "example" {
  name                       = "web"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]
  security_groups = [aws_security_group.example.id]
}

# リスナーの作成
resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }
}

# ターゲットグループの作成
resource "aws_alb_target_group" "blue" {
  name                 = "example-target"
  vpc_id               = aws_vpc.example.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_alb.example]
}

resource "aws_alb_target_group" "green" {
  name                 = "example-target2"
  vpc_id               = aws_vpc.example.id
  target_type          = "ip"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_alb.example]
}

resource "aws_alb_listener_rule" "example" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

#########################################################################
# ECS
#########################################################################
resource "aws_ecs_cluster" "example" {
  name = "nginx-cluster"
}

resource "aws_ecs_task_definition" "example" {
  container_definitions    = file("./example_task_definitions.json")
  family                   = "example"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.example.arn
}

resource "aws_ecs_service" "example" {
  name                              = "example-nginx-service"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.example.id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

#########################################################################
# CloudWatch Logs
#########################################################################
resource "aws_cloudwatch_log_group" "a0617_nginx" {
  name              = "/ecs/a0617_nginx"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "a0617_python" {
  name              = "/ecs/a0617_python"
  retention_in_days = 7
}

#########################################################################
# IAM
#########################################################################
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "example" {
  name   = "example-policy-ecs-task-execution"
  policy = data.aws_iam_policy_document.ecs_task_execution.json
}

resource "aws_iam_role" "example" {
  name               = "example-role-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

#######################################
# Parameter Store
#######################################

resource "aws_ssm_parameter" "account-id" {
  name  = "account-id"
  type  = "String"
  value = "823104559115"
}

resource "aws_ssm_parameter" "dockerhub-token" {
  name  = "dockerhub-token"
  type  = "String"
  value = var.dockerhub-token
}

resource "aws_ssm_parameter" "dockerhub-user" {
  name  = "dockerhub-user"
  type  = "String"
  value = "tsuyoshitakezawa"
}

resource "aws_ssm_parameter" "image-tag" {
  name  = "image-tag"
  type  = "String"
  value = "latest"
}

resource "aws_ssm_parameter" "image1" {
  name  = "image1"
  type  = "String"
  value = "823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/nginx"
}

resource "aws_ssm_parameter" "image2" {
  name  = "image2"
  type  = "String"
  value = "823104559115.dkr.ecr.ap-northeast-1.amazonaws.com/python"
}

resource "aws_ssm_parameter" "region" {
  name  = "region"
  type  = "String"
  value = "ap-northeast-1"
}

resource "aws_ssm_parameter" "github_personal_access_token" {
  name  = "github_personal_access_token"
  type  = "String"
  value = var.github_personal_access_token
}


#######################################
# CodeBuild_nginx
#######################################

resource "aws_iam_role" "nginx_build" {
  name = "nginx_build"

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

resource "aws_iam_role_policy" "nginx_build" {
  role = aws_iam_role.nginx_build.name

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

resource "aws_codebuild_project" "nginx_build" {
  name          = "nginx_build"
  description   = "nginx_build_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.nginx_build.arn

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
    buildspec       = "nginx_buildspec.yml"
  }

}


#######################################
# CodeBuild_python
#######################################


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



#######################################
# CodeDeploy
#######################################

resource "aws_codedeploy_app" "codedeploy" {
  compute_platform = "ECS"
  name             = "codedeploy"
}

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy_role"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
)
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "codedeploy_policy"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode(
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "ecs:DescribeServices",
                  "ecs:CreateTaskSet",
                  "ecs:UpdateServicePrimaryTaskSet",
                  "ecs:DeleteTaskSet",
                  "elasticloadbalancing:DescribeTargetGroups",
                  "elasticloadbalancing:DescribeListeners",
                  "elasticloadbalancing:ModifyListener",
                  "elasticloadbalancing:DescribeRules",
                  "elasticloadbalancing:ModifyRule",
                  "lambda:InvokeFunction",
                  "cloudwatch:DescribeAlarms",
                  "sns:Publish",
                  "s3:GetObject",
                  "s3:GetObjectVersion"
              ],
              "Resource": "*",
              "Effect": "Allow"
          },
          {
              "Action": [
                  "iam:PassRole"
              ],
              "Effect": "Allow",
              "Resource": "*",
              "Condition": {
                  "StringLike": {
                      "iam:PassedToService": [
                          "ecs-tasks.amazonaws.com"
                      ]
                  }
              }
          }
      ]
  }
)
}

resource "aws_codedeploy_deployment_group" "codedeploy_group" {
  app_name               = aws_codedeploy_app.codedeploy.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "codedeploy_group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.example.name
    service_name = aws_ecs_service.example.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.example.arn]
      }

      target_group {
        name = aws_alb_target_group.blue.name
      }

      target_group {
        name = aws_alb_target_group.green.name
      }
    }
  }
}

#######################################
# CodePipeline
#######################################

resource "aws_codepipeline" "codepipeline" {
  name     = "codepipeline-sample"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
      location = aws_s3_bucket.codepipeline_bucket1.bucket
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
        FileName                       = "imagedef.json"
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

resource "aws_s3_bucket" "codepipeline_bucket1" {
  bucket = "test1-bucket"
  acl    = "private"
}

resource "aws_codepipeline_webhook" "webhook" {
  name            = "webhook-fargate-deploy"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.codepipeline.name

  authentication_configuration {
    secret_token = aws_ssm_parameter.github_personal_access_token.value
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
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

#######################################
# Github
#######################################

resource "aws_codestarconnections_connection" "example" {
  name          = "example-connection"
  provider_type = "GitHub"
}

resource "github_repository_webhook" "webhook" {
  repository = "test0701"

  configuration {
    url          = aws_codepipeline_webhook.webhook.url
    content_type = "json"
    insecure_ssl = true
    secret       = aws_ssm_parameter.github_personal_access_token.value
  }

  events = ["push"]
}
