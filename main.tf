module "cloudwatch_dashboard" {
  source         = "./module/CLOUDWATCH/CLOUDWATCH-DASHBOARD"
  for_each       = local.dashboards
  dashboard_name = each.value["dashboard_name"]
  dashboard_body = each.value["dashboard_body"]
}    