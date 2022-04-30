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

      test_traffic_route {
        listener_arns = [aws_alb_listener.example2.arn]
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
