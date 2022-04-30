resource "aws_codestarconnections_connection" "example" {
  name          = "example-connection"
  provider_type = "GitHub"
}

resource "github_repository" "test0701" {
  name         = "test0701"
  description  = "Terraform acceptance tests"
  homepage_url = "https://github.com/tsuyoshi7777/test0701"

  visibility = "public"
}

resource "github_repository_webhook" "webhook" {
  repository = github_repository.test0701.name

  configuration {
    url          = aws_codepipeline_webhook.webhook.url
    content_type = "json"
    insecure_ssl = true
    secret       = aws_ssm_parameter.github_personal_access_token.value
  }

  events = ["push"]
}
