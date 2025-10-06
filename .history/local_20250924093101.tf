locals {
  dashboards = {
    "Amazon-Connect-Instance-Dashboard-dev-dale" = {
        dashboard_name = "Amazon-Connect-Instance-Dashboard-dev-dale"
      dashboard_body = jsondecode(file("${path.module}/dashboard_body.json"))

    }

  }
}  