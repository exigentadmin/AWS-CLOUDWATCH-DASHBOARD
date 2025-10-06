module "cloudwatch_dashboard" {
    source = "./module/CLOUDWATCH/CLOUDWATCH-DASHBOARD"
    for_each = local.
}    