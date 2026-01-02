resource "aws_route53_zone" "private" {
  name = join(".", slice(split(".", var.tfe_domain), 1, 3))

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name = "${var.prefix}-private-zone"
  }
}

data "aws_lb" "main" {
  depends_on = [
    terraform_data.bastion
  ]

  name = var.tfe_lb_name
}

resource "aws_route53_record" "tfe_lb" {
  zone_id = aws_route53_zone.private.zone_id
  name = var.tfe_domain
  type = "A"

  alias {
    name = data.aws_lb.main.dns_name
    zone_id = data.aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = aws_route53_zone.private.zone_id
  name = var.gitlab_domain
  type = "A"
  ttl = 300
  records = [
    aws_instance.gitlab.private_ip
  ]
}