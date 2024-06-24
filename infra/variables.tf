variable "aws_region" {
  description = "La region AWS où déployer les ressources"
  type        = string
}

variable "vpc_id" {
  description = "Le VPC où déployer les ressources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Les subnets privés où déployer les ressources"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Les subnets publics où déployer les ressources"
  type        = list(string)
}

variable "prefix" {
  description = "Le préfixe à ajouter aux ressources"
  type        = string
  default     = "demo-ljdc-2024"
}

variable "tags" {
  description = "Les tags à ajouter aux ressources"
  type        = map(string)
  default = {
    App = "Demo La Journée du Cloud"
  }
}

variable "app_image" {
  description = "L'image Docker à déployer"
  type = object({
    name = string
    tag  = string
  })
  default = {
    name = "elmhaidara/demo-ljdc"
    tag  = "1.0.0"
  }
}


variable "allowed_ip_adresses" {
  description = "Les adresses IP autorisées à accéder aux ressources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}