locals {
  # Extract parent domain from tfe_domain
  tfe_parent_domain = join(".", slice(split(".", var.tfe_domain), 1, length(split(".", var.tfe_domain))))
}

# Private Route53 Hosted Zone
resource "aws_route53_zone" "private" {
  name = local.tfe_parent_domain

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Data source to get the NLB created by AWS Load Balancer Controller
data "aws_lb" "tfe" {
  name = var.tfe_lb_name

  depends_on = [
    terraform_data.private_bastion
  ]
}

# Route53 record for TFE
resource "aws_route53_record" "tfe" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.tfe_domain
  type    = "A"

  alias {
    name                   = data.aws_lb.tfe.dns_name
    zone_id                = data.aws_lb.tfe.zone_id
    evaluate_target_health = true
  }
}

# Route53 record for GitLab
resource "aws_route53_record" "gitlab" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.gitlab_domain
  type    = "A"
  ttl     = 300
  records = [aws_instance.gitlab.private_ip]
}
