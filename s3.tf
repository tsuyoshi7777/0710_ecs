resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "test-bucket0710"
  acl    = "private"
}
