resource "aws_ecs_task_definition" "test0701" {
  container_definitions    = file("task-definitions/example_task_definitions.json")
  family                   = "test0701"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.example.arn
}
