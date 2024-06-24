resource "aws_secretsmanager_secret" "secrets" {
  name                    = "${var.prefix}-secrets"
  description             = "Secrets for the Django application"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id = aws_secretsmanager_secret.secrets.id
  secret_string = jsonencode({
    secret_key = random_password.django_secret_key.result
    db_pass    = random_password.db_pass.result
    db_name    = aws_db_instance.this.db_name
    db_user    = aws_db_instance.this.username
    db_host    = aws_db_instance.this.address
    db_engine  = "django.db.backends.postgresql"
    db_port    = aws_db_instance.this.port
  })
}

resource "random_password" "django_secret_key" {
  # Should not be changed after the first deployment and migration
  length  = 64
  special = true
}

