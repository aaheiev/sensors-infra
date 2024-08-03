include "root" {
  path = find_in_parent_folders()
}

dependency "dns_zone" {
  config_path = "../dns_zone"
}

dependency "tls_wildcard" {
  config_path = "../tls_wildcard"
}

inputs = {
  dns_zone_name      = dependency.dns_zone.outputs.main_dns_zone_name
  certificate_map_id = dependency.tls_wildcard.outputs.certificate_map_id
}

terraform {
  source = "${get_repo_root()}/stages/grafana"
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]
    arguments = [
      "-var-file=${get_repo_root()}/conf/google.tfvars",
    ]
  }
}
