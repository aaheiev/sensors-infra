include "root" {
  path = find_in_parent_folders()
}

inputs = {
  main_dns_zone_name   = "bijlmerdreef733"
  main_dns_zone_domain = "bijlmerdreef733.nl."
}

terraform {
  source = "${get_repo_root()}/modules/google-dns-zone"
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
