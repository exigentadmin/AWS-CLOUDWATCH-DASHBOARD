locals {
  # Merge instances from all regions into a single map: alias => { id, region }
  # If the same alias appears in multiple regions the last region wins (should not happen).
  all_instances = merge([
    for region, ds in data.external.connect_instances : {
      for alias, id in jsondecode(ds.result["instances"]) :
      alias => { id = id, region = region }
    }
  ]...)

  # Honour instance_aliases when set; otherwise use every discovered instance.
  target_instances = length(var.instance_aliases) > 0 ? {
    for alias in var.instance_aliases : alias => local.all_instances[alias]
  } : local.all_instances

  dashboards = {
    for alias, inst in local.target_instances :
    "Amazon-Connect-Instance-Dashboard-${alias}" => {
      dashboard_name = "Amazon-Connect-Instance-Dashboard-${alias}"
      dashboard_body = templatefile("${path.module}/JSON/dashboard_body.tftpl", {
        instance_id    = inst.id
        instance_alias = alias
        region         = inst.region
      })
    }
  }
}

locals {
  create_log_bucket         = var.log_bucket_name == ""
  effective_log_bucket_name = local.create_log_bucket ? "connect-cloudwatch-logs-${random_id.log_bucket[0].hex}" : var.log_bucket_name
  log_bucket_id             = local.create_log_bucket ? aws_s3_bucket.cloudwatch_logs[0].id : data.aws_s3_bucket.existing_log_bucket[0].id
  log_bucket_arn            = local.create_log_bucket ? aws_s3_bucket.cloudwatch_logs[0].arn : data.aws_s3_bucket.existing_log_bucket[0].arn
}
