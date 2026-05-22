# Discovers all Connect instances in each target region via the AWS CLI.
# Requires: AWS CLI in PATH, credentials with connect:ListInstances.
# Windows users: if "python3" is not found, change the command to "python".
data "external" "connect_instances" {
  for_each = toset(["us-east-1", "us-west-2"])
  program  = ["python3", "${path.module}/scripts/list_instances.py"]
  query    = { region = each.key }
}
