resource "aws_acm_certificate" "example" {
  domain_name               = data.aws_route53_zone.example.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 検証用DNSレコードの作成
resource "aws_route53_record" "example-test" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id = data.aws_route53_zone.example.id
  ttl     = 60
}

# DNSレコードの検証
resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example-test : record.fqdn]
}
