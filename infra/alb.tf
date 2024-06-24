resource "aws_alb" "app" {
  name                       = var.prefix
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
}

resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb"
  vpc_id      = var.vpc_id
  description = "SG for the ALB"
  tags = {
    Name = "${var.prefix}-alb"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    description = "Egress VPC"
    cidr_blocks = data.aws_vpc.this.cidr_block_associations[*].cidr_block
  }

  ingress {
    description = "Ingress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = var.allowed_ip_adresses
  }
}

resource "aws_lb_listener" "listeners" {
  for_each = {
    live = 80
    test = 8080
  }
  load_balancer_arn = aws_alb.app.arn
  port              = each.value

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\":\"404 Not Found\"}"
      status_code  = "404"
    }
  }
}

resource "aws_alb_target_group" "api" {
  for_each = {
    blue  = {}
    green = {}
  }
  name = "${var.prefix}-api-${each.key}"
  port = local.app_port

  target_type          = "ip"
  protocol             = "HTTP"
  deregistration_delay = 15
  slow_start           = 30

  vpc_id = var.vpc_id

  health_check {
    enabled  = true
    path     = "/__healthcheck/liveness-probe/"
    interval = 30
    timeout  = 5
  }

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_alb_listener_rule" "rules" {
  for_each = {
    /**
     Ici, il s'agit des valeurs initiales des target groups qui vont être utilisées par CodeDeploy.
     */
    live = "blue"
    test = "green"
  }
  listener_arn = aws_lb_listener.listeners[each.key].arn

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_alb_target_group.api[each.value].arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [
      # Champs gérés par CodeDeploy
      action
    ]
  }
}
