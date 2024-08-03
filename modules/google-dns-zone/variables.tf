variable "gcloud_project" {
  type        = string
  description = "Main GCP project"
}

variable "gcloud_region" {
  type        = string
  description = "Main GCP region"
  default     = "europe-west4"
}

variable "main_dns_zone_name" {
  type = string
}

variable "main_dns_zone_domain" {
  type = string
}

variable "main_dns_zone_enable_logging" {
  type    = bool
  default = false
}


# variable "gcr_repo_name_prefix" {
#   type    = string
#   default = "gcloud"
# }
#
# variable "github_token" {
#   type      = string
#   sensitive = true
# }
#
# variable "github_org_name" {
#   type    = string
#   default = "aaheiev"
# }
#
# variable "github_repo_name" {
#   type    = string
#   default = "gcloud"
# }
