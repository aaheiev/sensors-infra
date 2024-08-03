locals {
  host_rules = {
    grafana = {
      hosts           = [local.app_fqdn]
      default_backend = google_compute_backend_service.backend_service.id
      paths = {
        "${google_compute_backend_service.backend_service.id}" = ["/"]
      }
    }
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  description     = "Url mapping to the ${var.name} services"
  default_service = google_compute_backend_service.backend_service.id
  dynamic "host_rule" {
    for_each = local.host_rules
    content {
      hosts        = host_rule.value["hosts"]
      path_matcher = host_rule.key
    }
  }
  dynamic "path_matcher" {
    for_each = local.host_rules
    content {
      name            = path_matcher.key
      default_service = path_matcher.value["default_backend"]

      dynamic "path_rule" {
        for_each = path_matcher.value["paths"]
        content {
          paths   = path_rule.value
          service = path_rule.key
        }
      }
    }
  }
}

resource "google_compute_url_map" "http_https_redirect" {
  name        = "${var.name}-http-https-redirect"
  description = "HTTP Redirect map"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_global_address" "global_lb_address" {
  provider   = google-beta
  project    = var.gcloud_project
  name       = "${var.name}-global-lb-address"
  ip_version = "IPV4"
}

data "google_compute_global_address" "global_lb_address" {
  depends_on = [google_compute_global_address.global_lb_address]
  name       = "${var.name}-global-lb-address"
  project    = var.gcloud_project
}

resource "google_dns_record_set" "grafana_a_record" {
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  name         = local.app_fqdn
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.global_lb_address.address]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  provider = google-beta
  project  = var.gcloud_project
  name     = "${var.name}-http-proxy"
  url_map  = google_compute_url_map.http_https_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  provider              = google-beta
  project               = var.gcloud_project
  name                  = "${var.name}-http"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  ip_address            = data.google_compute_global_address.global_lb_address.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_target_https_proxy" "https_proxy" {
  provider        = google-beta
  project         = var.gcloud_project
  name            = "${var.name}-https-proxy"
  url_map         = google_compute_url_map.url_map.id
  certificate_map = "//certificatemanager.googleapis.com/${var.certificate_map_id}"
}

resource "google_compute_global_forwarding_rule" "https" {
  provider              = google-beta
  project               = var.gcloud_project
  name                  = "${var.name}-https"
  target                = google_compute_target_https_proxy.https_proxy.self_link
  ip_address            = data.google_compute_global_address.global_lb_address.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
