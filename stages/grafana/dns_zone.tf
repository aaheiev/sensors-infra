data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}

locals {
  fqdn          = trimsuffix(data.google_dns_managed_zone.dns_zone.dns_name, ".")
  dns_zone_name = data.google_dns_managed_zone.dns_zone.name
  app_fqdn      = "${var.name}.${data.google_dns_managed_zone.dns_zone.dns_name}"
}
