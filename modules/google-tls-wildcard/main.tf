data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}

locals {
  fqdn          = trimsuffix(data.google_dns_managed_zone.dns_zone.dns_name, ".")
  dns_zone_name = data.google_dns_managed_zone.dns_zone.name
}

resource "google_certificate_manager_dns_authorization" "dns_authorization" {
  name        = "${local.dns_zone_name}-dns-authorization"
  description = "DNS authorization for ${local.fqdn} to support wildcard certificates"
  domain      = local.fqdn
}

resource "google_dns_record_set" "dns_authorization_wildcard_certificate" {
  name         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].name
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  type         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].type
  ttl          = 60
  rrdatas      = [google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].data]
}

resource "google_certificate_manager_certificate" "wildcard_ssl_certificate" {
  name        = "${local.dns_zone_name}-wildcard"
  description = "Wildcard certificate for ${local.fqdn} and sub-domains"

  managed {
    domains = [local.fqdn, "*.${local.fqdn}"]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.dns_authorization.id
    ]
  }
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name        = "${local.dns_zone_name}-certificate-map"
  description = "${local.fqdn} certificate map containing the domain names and sub-domains names for the SSL certificate"
}

resource "google_certificate_manager_certificate_map_entry" "domain_certificate_entry" {
  name         = "${local.dns_zone_name}-domain-cert-entry"
  description  = "${local.fqdn} certificate entry"
  map          = google_certificate_manager_certificate_map.certificate_map.name
  certificates = [google_certificate_manager_certificate.wildcard_ssl_certificate.id]
  hostname     = local.fqdn
}

resource "google_certificate_manager_certificate_map_entry" "sub_domain_certificate_entry" {
  name         = "${local.dns_zone_name}-sub-domain-entry"
  description  = "*.${local.fqdn} certificate entry"
  map          = google_certificate_manager_certificate_map.certificate_map.name
  certificates = [google_certificate_manager_certificate.wildcard_ssl_certificate.id]
  hostname     = "*.${local.fqdn}"
}
