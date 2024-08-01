resource "google_dns_managed_zone" "main" {
  name        = var.main_dns_zone_name
  dns_name    = var.main_dns_zone_domain
  labels      = local.default_labels
  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }
  cloud_logging_config {
    enable_logging = var.main_dns_zone_enable_logging
  }
}

import {
  id = "bijlmerdreef733"
  to = google_dns_managed_zone.main
}

# output "main_dns_zone_name" {
#   value = google_dns_managed_zone.main.name
# }
