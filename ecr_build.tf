resource "null_resource" "ecr_nginx_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin aws-id.dkr.ecr.ap-northeast-1.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t nginx -f nginx/ecs_Dockerfile ."
  }

  provisioner "local-exec" {
    command = "docker tag nginx:latest aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest"
  }

  provisioner "local-exec" {
    command = "docker push aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest"
  }
}

resource "null_resource" "ecr_python_push" {
  provisioner "local-exec" {
    command = "docker build -t python -f python/ecs_Dockerfile ."
  }

  provisioner "local-exec" {
    command = "docker tag python:latest aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/python:latest"
  }

  provisioner "local-exec" {
    command = "docker push aws-id.dkr.ecr.ap-northeast-1.amazonaws.com/python:latest"
  }
}
