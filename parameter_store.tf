resource "aws_ssm_parameter" "account-id" {
  name  = "account-id"
  type  = "String"
  value = "aws-id"
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
  value = "aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/nginx"
}

resource "aws_ssm_parameter" "image2" {
  name  = "image2"
  type  = "String"
  value = "aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/python"
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
