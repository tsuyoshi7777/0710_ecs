# rds_import

resource "null_resource" "rds_import" {
  provisioner "local-exec" {
    command = "ssh -i "test_0605.pem" ec2-user@aws_instance.bastion_host.public_dns"
  }

  provisioner "local-exec" {
    command = "sudo yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm"
  }

  provisioner "local-exec" {
    command = "sudo yum install -y mysql-community-server"
  }

  provisioner "local-exec" {
    command = "mysql -h aws_db_instance.example_rds.endpoint -P 3306 -u var.aws_db_username -p < '/Users/tsuyoshitakezawa/Desktop/0710/sh_files/rds_import.sql'"
  }
}
