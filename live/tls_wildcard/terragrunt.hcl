include "root" {
  path = find_in_parent_folders()
}

dependency "dns_zone" {
  config_path = "../dns_zone"
}

inputs = {
  dns_zone_name = dependency.dns_zone.outputs.main_dns_zone_name
}

terraform {
  source = "${get_repo_root()}/modules/google-tls-wildcard"
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
