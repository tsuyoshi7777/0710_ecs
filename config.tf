variable dockerhub-token {}
variable github_personal_access_token {}
variable aws_db_username {}
variable aws_db_password {}
variable my_ip {}

terraform {
  required_version = "~> 1.0.0"
}

provider "aws" {
  region     = "ap-northeast-1"
}
