variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "routes" {
  type = map(object({
    route_key       = string
    integration_uri = string
    function_name   = string
  }))
}
