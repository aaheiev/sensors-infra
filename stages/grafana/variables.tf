variable "name" {
  type    = string
  default = "grafana"
}

variable "gcloud_project" {
  type        = string
  description = "Main GCP project"
}

variable "gcloud_region" {
  type        = string
  description = "Main GCP region"
  default     = "europe-west4"
}

variable "dns_zone_name" {
  type = string
}

variable "certificate_map_id" {
  type = string
}
