# AWS CloudWatch Dashboard — Amazon Connect

Terraform project that auto-discovers Amazon Connect instances across multiple AWS regions and, for each one, creates a per-instance CloudWatch dashboard, a set of CloudWatch alarms on key voice metrics, and a notification pipeline that routes alarm state changes to email and/or a Microsoft Teams channel. It also provisions an S3 bucket for CloudWatch log exports with a 2-year retention policy.

## How it works

1. A Python script (`scripts/list_instances.py`) is called by Terraform's `external` data source for each configured region. It runs `aws connect list-instances` and returns a map of `alias → instance ID`.
2. `local.tf` merges results from all regions into a single map, then builds a `dashboards` local keyed by instance alias.
3. The root `main.tf` calls the `module/CLOUDWATCH/CLOUDWATCH-DASHBOARD` module once per instance, passing a rendered copy of `JSON/dashboard_body.tftpl` as the dashboard body.
4. The module creates an `aws_cloudwatch_dashboard` resource plus a set of `aws_cloudwatch_metric_alarm` resources (`alarms.tf`) covering the key voice metrics. Dashboard and alarms are created in the instance's own region — alarms must live in the same region as the metrics they watch. Alarm and OK actions publish to the SNS topic in that region.
5. `sns.tf` creates a `connect-cloudwatch-alarms` SNS topic in each configured region (CloudWatch alarm actions can only target a topic in the alarm's own region) and, when `alarm_email` is set, an email subscription per topic. When `teams_webhook_url` is set, `lambda.tf` deploys the `module/LAMBDA/SNS-TEAMS-WEBHOOK` module — a Python Lambda subscribed to every regional topic that posts a formatted MessageCard to a Microsoft Teams incoming webhook on every alarm state change.
6. `s3.tf` creates (or references) an S3 bucket that CloudWatch Logs is permitted to write export tasks to from each configured region.

Dashboards are named `<alias>-connect-metrics-dashboard` and alarms `<alias>-<metric>` (e.g. `default-org-cc-dev-missed-calls`); both are created in the region where each instance lives, via the AWS provider's per-resource `region` attribute.

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI in `PATH` with credentials that have:
  - `connect:ListInstances`, `cloudwatch:PutDashboard`, `cloudwatch:PutMetricAlarm`
  - `sns:CreateTopic`, `sns:Subscribe` (and `sns:SetTopicAttributes`)
  - If deploying the Teams webhook: `lambda:*` for the function, plus `iam:CreateRole` / `iam:AttachRolePolicy` for its execution role
  - If auto-creating the log bucket: `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:PutEncryptionConfiguration`, `s3:PutBucketVersioning`, `s3:PutLifecycleConfiguration`
- Python 3 in `PATH`. On Linux/macOS the interpreter is usually `python3`; on Windows it is usually `python`. Set the `python_command` variable to match (see Variables below) — no tracked file needs editing.

## Project structure

```
.
├── main.tf                                    # Root module — iterates dashboards local
├── local.tf                                   # Merges per-region instance data; log bucket name resolution
├── data.tf                                    # External data source — runs list_instances.py per region
├── sns.tf                                     # SNS alarm topic + optional email subscription
├── lambda.tf                                  # Optional Teams webhook Lambda module (when teams_webhook_url set)
├── s3.tf                                      # S3 log bucket (create or reference existing)
├── outputs.tf                                 # Outputs: dashboards, alarm topic, Teams Lambda, log bucket, instances
├── variable.tf                                # Input variables
├── terraform.tf                               # Provider and backend configuration
├── terraform.tfvars                           # Local variable overrides (gitignored by default)
├── JSON/
│   ├── dashboard_body.tftpl                   # Terraform template for the dashboard JSON
│   └── dashboard_body.json                    # Static reference copy of the dashboard JSON
├── scripts/
│   └── list_instances.py                      # Discovers Connect instances via AWS CLI
└── module/
    ├── CLOUDWATCH/
    │   └── CLOUDWATCH-DASHBOARD/
    │       ├── main.tf                        # aws_cloudwatch_dashboard resource (created in var.region)
    │       ├── alarms.tf                       # Per-instance aws_cloudwatch_metric_alarm resources (created in var.region)
    │       ├── data.tf                         # (empty placeholder)
    │       ├── outputs.tf                      # dashboard_name, dashboard_arn outputs
    │       └── variable.tf                     # dashboard/instance/region/sns_topic_arn variables
    └── LAMBDA/
        └── SNS-TEAMS-WEBHOOK/
            ├── main.tf                        # Lambda function, IAM role, per-topic SNS subscriptions
            ├── outputs.tf                     # lambda_arn, lambda_function_name outputs
            ├── variable.tf                    # function_name, teams_webhook_url, sns_topic_arns
            └── src/
                └── handler.py                 # Posts alarm MessageCards to the Teams webhook
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

To destroy all dashboards:

```bash
terraform destroy
```

## Example deployment (default-org dev)

A typical deployment of this configuration for an organization (`default-org`) applied to account `123456789012` (state is local in `terraform.tfstate`; use an AWS profile with the permissions listed under Prerequisites, e.g. `123456789012_default-org-dev-admins`) looks like:

- Instance: `default-org-cc-dev` in us-west-2, with its dashboard and all six alarms in that region
- Notifications: `connect-cloudwatch-alarms` SNS topic in us-west-2 with a confirmed email subscription for `alerts@default-org.com`; the Teams webhook Lambda is not deployed
- Log export bucket: `connect-cloudwatch-logs-<random-hex>` (in us-east-1 — see the note under Logging and retention)

A CloudFormation port of this solution lives in the sibling repo `aws-cloudwatch-dashboard-cf/default-org`. If a deployment moves to CloudFormation, follow that repo's "Migrating from the live Terraform deployment" README section — the stacks reuse the same resource names, so the Terraform-managed resources must be destroyed first.

## Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `instance_aliases` | `list(string)` | `[]` | Aliases of Connect instances to create dashboards for. Leave empty to create dashboards for every discovered instance across all configured regions. |
| `aws_regions` | `list(string)` | `["us-east-1", "us-west-2"]` | AWS regions to scan for Amazon Connect instances and permit for CloudWatch Logs exports. |
| `log_bucket_name` | `string` | `""` | Name of an existing S3 bucket to use for CloudWatch log exports. Leave empty to auto-create a new bucket with a 2-year retention lifecycle. |
| `alarm_email` | `string` | `""` | Email address to subscribe to the alarm SNS topic. Leave empty to create the topic without an email subscription. The address must confirm the SNS subscription email before it receives notifications. |
| `teams_webhook_url` | `string` (sensitive) | `""` | Microsoft Teams incoming webhook URL for alarm notifications. Leave empty to skip the Lambda deployment entirely. |
| `python_command` | `string` | `"python3"` | Command used to run `scripts/list_instances.py`. Set to `"python"` on Windows. |

**Example `terraform.tfvars`** (restrict to a specific instance, use an existing log bucket, and enable both notification channels):

```hcl
instance_aliases  = ["sandbox-lqtc"]
aws_regions       = ["us-east-1", "us-west-2"]
log_bucket_name   = "my-existing-log-bucket"
alarm_email       = "oncall@example.com"
teams_webhook_url = "https://example.webhook.office.com/webhookb2/..."
```

## Alarms and notifications

For each Connect instance, the dashboard module (`module/CLOUDWATCH/CLOUDWATCH-DASHBOARD/alarms.tf`) creates a set of CloudWatch metric alarms on the `AWS/Connect` namespace, in the instance's region. Both the alarm and OK transitions publish to the `connect-cloudwatch-alarms` SNS topic in that region, so you are notified when a condition trips *and* when it clears.

| Alarm (`<alias>-…`) | Metric | Condition | Period |
|---|---|---|---|
| `concurrent-calls-pct` | `ConcurrentCallsPercentage` (Max) | > 80% | 15 min |
| `missed-calls` | `MissedCalls` (Sum) | > 5 | 1 hour |
| `calls-breaching-quota` | `CallsBreachingConcurrencyQuota` (Sum) | > 0 | 15 min |
| `throttled-calls` | `ThrottledCalls` (Sum) | > 0 | 15 min |
| `packet-loss-rate` | `PacketLossRate` (Avg) | > 1% | 15 min |
| `contact-flow-errors` | `ContactFlowErrors` (Sum, all flows via metric query) | > 5 | 1 hour |

All alarms use `treat_missing_data = "notBreaching"`, so a quiet instance stays in the OK state.

### Notification channels

A `connect-cloudwatch-alarms` SNS topic is always created in each region listed in `aws_regions` — CloudWatch alarm actions can only target a topic in the alarm's own region. Two optional subscribers fan out from each topic:

- **Email** — set `alarm_email` to subscribe an address to every regional topic. AWS sends one confirmation email per region that the recipient must accept before notifications arrive.
- **Microsoft Teams** — set `teams_webhook_url` to deploy the `module/LAMBDA/SNS-TEAMS-WEBHOOK` Lambda. It subscribes to each regional topic (SNS delivers to Lambda across regions) and, on each alarm state change, posts a color-coded MessageCard (red = ALARM, green = OK, orange = INSUFFICIENT_DATA) to the Teams incoming webhook. Leaving `teams_webhook_url` empty skips the Lambda, IAM role, and subscriptions entirely.

To create a Teams incoming webhook URL, add an **Incoming Webhook** connector to the target Teams channel and copy the generated URL. Treat it as a secret — the variable is marked `sensitive`.

## Logging and retention

CloudWatch log exports need an S3 destination. This project handles that in two modes, controlled by the `log_bucket_name` variable.

### Auto-created bucket (default)

When `log_bucket_name` is left empty, Terraform creates a new S3 bucket named `connect-cloudwatch-logs-<random-hex>` with the following configuration:

| Setting | Value |
|---|---|
| Encryption | AES-256 (SSE-S3) |
| Versioning | Enabled |
| Current-version expiration | 730 days (2 years) |
| Noncurrent-version expiration | 730 days (2 years) |
| Bucket policy | Grants CloudWatch Logs service principals for each region in `aws_regions` `GetBucketAcl` and `PutObject` with `bucket-owner-full-control` ACL |

The `PutObject` policy condition (`s3:x-amz-acl: bucket-owner-full-control`) ensures the bucket owner retains full control of objects written by the CloudWatch Logs service.

Note: the bucket is created in the default provider region (`us-east-1`, set in `terraform.tf`), regardless of `aws_regions`. CloudWatch log export tasks require the destination bucket to be in the same region as the log group, so exporting log groups from other regions (e.g. an instance deployed in us-west-2) needs a bucket in that region — a known limitation of this configuration.

### Bring your own bucket

Set `log_bucket_name` to the name of an existing bucket:

```hcl
log_bucket_name = "my-existing-log-bucket"
```

Terraform will reference the existing bucket instead of creating one. **The bucket policy is not applied to externally-managed buckets** — you must ensure the existing bucket already has a policy that permits the CloudWatch Logs service principals for each region in `aws_regions` to call `s3:GetBucketAcl` and `s3:PutObject` (with the `bucket-owner-full-control` ACL condition).

### Triggering log exports

The S3 bucket is the *destination* for CloudWatch log export tasks. Export tasks must be triggered separately — either manually via the AWS Console (`CloudWatch → Log groups → Actions → Export data to Amazon S3`) or programmatically via the AWS CLI:

```bash
aws logs create-export-task \
  --log-group-name /aws/connect/... \
  --from <epoch-ms> \
  --to <epoch-ms> \
  --destination <bucket-name> \
  --destination-prefix <prefix>
```

## Outputs

After `terraform apply`, the following values are available via `terraform output`:

| Output | Description |
|---|---|
| `dashboard_names` | List of all CloudWatch dashboard names created |
| `dashboard_arns` | Map of dashboard key to ARN |
| `alarm_sns_topic_arns` | Map of region to the ARN of the alarm SNS topic in that region |
| `teams_webhook_lambda_arn` | ARN of the Teams webhook Lambda, or `null` if `teams_webhook_url` was not set |
| `log_bucket_name` | Name of the S3 bucket used for log exports |
| `log_bucket_arn` | ARN of the S3 bucket used for log exports |
| `discovered_instances` | Map of Connect instance alias to `{ id, region }` across all configured regions |

## Configured regions

Regions are configured with the `aws_regions` variable:

```hcl
aws_regions = ["us-east-1", "us-west-2"]
```

Add or remove regions in `terraform.tfvars` to control both Connect discovery and the CloudWatch Logs export bucket policy.

## Dashboard contents

Each dashboard covers three channel types:

**Voice Metrics**
- Total Inbound + Outbound Calls (Sum)
- Queue Size (by queue name)
- Concurrent Calls % — gauge (Max)
- Concurrent Calls (Max)
- Queue Wait Times (by queue name)
- Calls Exceeding Concurrency Limit — gauge (Sum)
- Throttled Calls (Sum)
- Queue Capacity Exceeded (by queue name)
- Missed Calls — gauge (Sum)
- Packet Loss Rate (Avg)
- Active Calls (Max)
- Contact Flow Errors (by flow name)

**Chat Metrics**
- Concurrent Active Chats (Max)

**Task Metrics**
- Concurrent Active Tasks (Max)

All time-series widgets use a 15-minute period. Use the dashboard **Actions → Period Override** to change the interval at runtime.

Amazon Connect CloudWatch metric definitions: https://docs.aws.amazon.com/connect/latest/adminguide/monitoring-cloudwatch.html

## Getting the source JSON from an existing dashboard

To copy the JSON body from a dashboard already in the AWS Console:

1. Sign in to the AWS Management Console and open CloudWatch.
2. In the left pane, click **Dashboards**.
3. Click the dashboard name to open it.
4. Click **Actions → View/edit source**.
5. Copy the JSON and paste it into `JSON/dashboard_body.json` (or use it directly as the `dashboard_body` argument in the module).

### Dashboard coordinate system

Widget positions use a grid measured in columns (x) and rows (y). The x-coordinate is the distance from the left edge and the y-coordinate is the distance from the top. The dashboard grid is 24 columns wide.
