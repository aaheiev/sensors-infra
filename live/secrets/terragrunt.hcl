include "root" {
  path = find_in_parent_folders()
}

inputs = {
  name = "grafana"
}

terraform {
  source = "${get_repo_root()}/modules/google-secrets"
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
