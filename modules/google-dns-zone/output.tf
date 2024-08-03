output "main_dns_zone_name" {
  value = google_dns_managed_zone.main.name
}

/*
output "main_dns_zone_dns_name" {
  value = google_dns_managed_zone.main.dns_name
}

output "main_dns_zone_dns_fdqn" {
  value = trimsuffix(google_dns_managed_zone.main.dns_name, ".")
}
*/
