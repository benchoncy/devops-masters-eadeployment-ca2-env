variable "init" {
  type    = bool
  default = false
}

variable "app_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "max_replicas" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "port" {
  type    = number
  default = 80
}

variable "external_ingress" {
  type    = bool
  default = false
}

variable "green" {
  type = number
}

variable "blue" {
  type = number
}

variable "liveness_probe" {
  type = object({
    initial_delay           = number
    interval_seconds        = number
    failure_count_threshold = number
    path                    = string
    port                    = number
    transport               = string
  })
  default = {
    initial_delay           = 15
    interval_seconds        = 10
    failure_count_threshold = 5
    path                    = "/"
    port                    = 80
    transport               = "HTTP"
  }
}

variable "env_vars" {
  type    = map(string)
  default = {}
}