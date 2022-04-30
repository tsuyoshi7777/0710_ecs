data "aws_route53_zone" "example" {
  name = "takezawatsuyoshi7777.com"
}

## ALBのDNSレコードの定義
resource "aws_route53_record" "example" {
  name    = data.aws_route53_zone.example.name
  zone_id = data.aws_route53_zone.example.id
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_alb.example.dns_name
    zone_id                = aws_alb.example.zone_id
  }
}
