resource "aws_acm_certificate" "cert" {
  domain_name       = local.dns_record
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}


data "aws_route53_zone" "zone" {
  name  = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "airflow" {
  count   = var.route53_zone_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.zone.id
  name    = local.dns_record
  type    = "A"

  alias {
    name                   = aws_lb.airflow.dns_name
    zone_id                = aws_lb.airflow.zone_id
    evaluate_target_health = "false"
  }
}

// AWS Record validation
resource "aws_route53_record" "validation" {

  allow_overwrite = true
  name            = local.main_acm_domain_validation_option.resource_record_name
  records         = [ local.main_acm_domain_validation_option.resource_record_value ]
  ttl             = 60
  type            = local.main_acm_domain_validation_option.resource_record_type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

locals {
  main_acm_domain_validation_option = tolist(aws_acm_certificate.cert.domain_validation_options)[0]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.validation.fqdn]
}
