resource "aws_cloudwatch_log_group" "anginx" {
  name              = "/ecs/anginx"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "apython" {
  name              = "/ecs/apython"
  retention_in_days = 7
}
