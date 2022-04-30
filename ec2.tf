resource "aws_instance" "bastion_host" {
    ami = "ami-0b276ad63ba2d6009"
    instance_type = "t2.micro"
    key_name   = "test_0605"
    vpc_security_group_ids = [aws_security_group.ec2.id]
    subnet_id = aws_subnet.public_0.id
    tags  = {
        Name = "bastion_host"
    }
}
