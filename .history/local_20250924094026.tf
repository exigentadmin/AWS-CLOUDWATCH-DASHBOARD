locals {
  dashboards = {
    "Amazon-Connect-Instance-Dashboard-dev-dale" = {
        dashboard_name = "Amazon-Connect-Instance-Dashboard-dev-dale"
      dashboard_body = file("${path.module}/dashboard_body.json")

    }

  }
}  