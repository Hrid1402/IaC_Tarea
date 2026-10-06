variable "aws_profile" {
  description = "Perfil local de AWS CLI"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue dev, qa o prod"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], lower(var.environment))
    error_message = "El environment debe ser dev, qa o prod. "
  }
}