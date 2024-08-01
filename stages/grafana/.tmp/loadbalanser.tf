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

resource "google_compute_global_address" "global_lb_ip_address" {
  name        = "${var.name}-lb-ip"
  description = "Public IP address of ${var.name} Global HTTPS load balancer"
}

resource "google_dns_record_set" "grafana_a_record" {
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  name         = local.app_fqdn
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.global_lb_ip_address.address]
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

resource "google_compute_target_http_proxy" "http_proxy" {
  name        = "${var.name}-http-webserver-proxy"
  description = "Redirect proxy mapping for the Load balancer"
  url_map     = google_compute_url_map.http_https_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name        = "http-forwarding-rule"
  description = "Global external load balancer HTTP redirect"
  ip_address  = google_compute_global_address.global_lb_ip_address.id
  port_range  = "80"
  target      = google_compute_target_http_proxy.http_proxy.self_link
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name            = "${var.name}-https-webserver-proxy"
  description     = "HTTPS Proxy mapping for the Load balancer including wildcard ssl certificate"
  url_map         = google_compute_url_map.url_map.self_link
  certificate_map = "//${google_project_service.certificate_manager.service}/${google_certificate_manager_certificate_map.certificate_map.id}"
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name        = "${var.name}-https-forwarding-rule"
  description = "Global external load balancer"
  ip_address  = google_compute_global_address.global_lb_ip_address.id
  port_range  = "443"
  target      = google_compute_target_https_proxy.https_proxy.self_link
}






# resource "google_dns_record_set" "grafana_aaaa_record" {
#   managed_zone = data.google_dns_managed_zone.dns_zone.name
#   name         = "${var.name}2.${data.google_dns_managed_zone.dns_zone.dns_name}"
#   type         = "AAAA"
#   rrdatas      = [google_compute_global_address.global_lb_ip_address.a]
# }

# resource "google_compute_global_address" "global-lb-address" {
#   provider   = google-beta
#   project    = var.gcloud_project
#   name       = "${var.name}-address"
#   ip_version = "IPV4"
# }
#
# data "google_compute_global_address" "global-lb-address" {
#   depends_on = [google_compute_global_address.global-lb-address]
#   name       = "${var.name}-address"
#   project    = var.gcloud_project
# }

// TODO: create A record
# locals {
#   host_rules = {
#     buxcharts = {
#       hosts           = ["grafana2.bijlmerdreef733.nl"]
#       default_backend = google_compute_backend_service.backend_service.id
#       paths = {
#         "${google_compute_backend_service.backend_service.id}" = ["/"]
#       }
#     }
#   }
# }

# resource "google_compute_url_map" "urlmap" {
#   name        = "${var.name}-urlmap"
#   description = "${var.name} Url Map"
#   default_service = google_compute_backend_service.backend_service.id
#
#   dynamic "host_rule" {
#     for_each = local.host_rules
#     content {
#       hosts        = host_rule.value["hosts"]
#       path_matcher = host_rule.key
#     }
#   }
#
#   dynamic "path_matcher" {
#     for_each = local.host_rules
#     content {
#       name            = path_matcher.key
#       default_service = path_matcher.value["default_backend"]
#
#       dynamic "path_rule" {
#         for_each = path_matcher.value["paths"]
#         content {
#           paths   = path_rule.value
#           service = path_rule.key
#         }
#       }
#     }
#   }
# }
