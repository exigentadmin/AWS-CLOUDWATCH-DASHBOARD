# Discovers all Connect instances in each target region via the AWS CLI.
# Requires: AWS CLI in PATH, credentials with connect:ListInstances.
# The interpreter is configurable via var.python_command ("python3" on
# Linux/macOS, "python" on Windows) so no tracked file needs editing.
data "external" "connect_instances" {
  for_each = toset(var.aws_regions)
  program  = [var.python_command, "${path.module}/scripts/list_instances.py"]
  query    = { region = each.key }
}
