# AWS CloudWatch Dashboard — Amazon Connect

Terraform project that auto-discovers Amazon Connect instances across multiple AWS regions, creates a per-instance CloudWatch dashboard for each one, and provisions an S3 bucket for CloudWatch log exports with a 2-year retention policy.

## How it works

1. A Python script (`scripts/list_instances.py`) is called by Terraform's `external` data source for each configured region. It runs `aws connect list-instances` and returns a map of `alias → instance ID`.
2. `local.tf` merges results from all regions into a single map, then builds a `dashboards` local keyed by instance alias.
3. The root `main.tf` calls the `module/CLOUDWATCH/CLOUDWATCH-DASHBOARD` module once per instance, passing a rendered copy of `JSON/dashboard_body.tftpl` as the dashboard body.
4. The module creates an `aws_cloudwatch_dashboard` resource.
5. `s3.tf` creates (or references) an S3 bucket that CloudWatch Logs is permitted to write export tasks to from each configured region.

Dashboards are named `<alias>-connect-metrics-dashboard` and deployed to the region where each instance lives.

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI in `PATH` with credentials that have `connect:ListInstances`, `cloudwatch:PutDashboard`, and (if auto-creating the log bucket) `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:PutEncryptionConfiguration`, `s3:PutBucketVersioning`, `s3:PutLifecycleConfiguration` permissions
- Python 3 (`python3` on Linux/Mac; on Windows use `python` — see note in `data.tf`)

## Project structure

```
.
├── main.tf                                    # Root module — iterates dashboards local
├── local.tf                                   # Merges per-region instance data; log bucket name resolution
├── data.tf                                    # External data source — runs list_instances.py per region
├── s3.tf                                      # S3 log bucket (create or reference existing)
├── outputs.tf                                 # Outputs: dashboard names/ARNs, log bucket, discovered instances
├── variable.tf                                # Input variables
├── terraform.tf                               # Provider and backend configuration
├── terraform.tfvars                           # Local variable overrides (gitignored by default)
├── JSON/
│   ├── dashboard_body.tftpl                   # Terraform template for the dashboard JSON
│   └── dashboard_body.json                    # Static reference copy of the dashboard JSON
├── scripts/
│   └── list_instances.py                      # Discovers Connect instances via AWS CLI
└── module/
    └── CLOUDWATCH/
        └── CLOUDWATCH-DASHBOARD/
            ├── main.tf                        # aws_cloudwatch_dashboard resource
            ├── outputs.tf                     # dashboard_name, dashboard_arn outputs
            └── variable.tf                    # dashboard_name, dashboard_body variables
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

## Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `instance_aliases` | `list(string)` | `[]` | Aliases of Connect instances to create dashboards for. Leave empty to create dashboards for every discovered instance across all configured regions. |
| `log_bucket_name` | `string` | `""` | Name of an existing S3 bucket to use for CloudWatch log exports. Leave empty to auto-create a new bucket with a 2-year retention lifecycle. |

**Example `terraform.tfvars`** (restrict to a specific instance and use an existing log bucket):

```hcl
instance_aliases = ["sandbox-lqtc"]
log_bucket_name  = "my-existing-log-bucket"
```

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
| Bucket policy | Grants CloudWatch Logs service principals in `us-east-1` and `us-west-2` `GetBucketAcl` and `PutObject` with `bucket-owner-full-control` ACL |

The `PutObject` policy condition (`s3:x-amz-acl: bucket-owner-full-control`) ensures the bucket owner retains full control of objects written by the CloudWatch Logs service.

### Bring your own bucket

Set `log_bucket_name` to the name of an existing bucket:

```hcl
log_bucket_name = "my-existing-log-bucket"
```

Terraform will reference the existing bucket instead of creating one. **The bucket policy is not applied to externally-managed buckets** — you must ensure the existing bucket already has a policy that permits `logs.us-east-1.amazonaws.com` and `logs.us-west-2.amazonaws.com` to call `s3:GetBucketAcl` and `s3:PutObject` (with the `bucket-owner-full-control` ACL condition).

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
| `log_bucket_name` | Name of the S3 bucket used for log exports |
| `log_bucket_arn` | ARN of the S3 bucket used for log exports |
| `discovered_instances` | Map of Connect instance alias to `{ id, region }` across all configured regions |

## Configured regions

Regions are hardcoded in `data.tf`:

```hcl
for_each = toset(["us-east-1", "us-west-2"])
```

Add or remove regions by editing that `toset(...)` list.

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
