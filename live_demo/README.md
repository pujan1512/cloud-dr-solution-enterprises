# Live AWS disaster-recovery demonstration

This is a deliberately small, real cloud demonstration: two independently deployed EC2 web servers in different AWS regions, Route 53 HTTP health checks, and primary/secondary DNS failover. Each region also has a private, versioned S3 bucket for manually uploaded backups. The live flow does **not** implement a database, automatic cross-region data replication, reverse synchronization, Lambda failover, or measured RTO/RPO. The old dashboard and older scripts are simulations/prototypes and are not evidence of this flow.

## Prerequisites and cost

- An AWS account with valid credentials and permissions for CloudFormation, EC2, IAM, S3, Route 53 and Systems Manager. Run `aws sts get-caller-identity` to verify access.
- AWS CLI, PowerShell and internet access. Two supported AWS regions with sufficient EC2 quota.
- A domain or subdomain whose delegation you can manage for normal browser DNS. Without one, you can still query the hosted zone's authoritative name server directly; that does not make the name publicly delegated.
- Running instances, EBS, two public IPv4 addresses, S3, Route 53 hosted zone, health checks, DNS queries and other resources can incur charges. Review the AWS Pricing Calculator and available credits for your account. No exact free-tier or price guarantee is made. Both instances run continuously until stacks are deleted.
- This is a teaching demo, not production infrastructure: HTTP has no TLS, the sample is a static page, and it has not undergone deployment or security validation.

Run from this directory in PowerShell. Commands create billable AWS resources:

```powershell
aws sts get-caller-identity
.\demo.ps1 -Action deploy-regions
```

This creates `clg-dr-primary` in `us-east-1` and `clg-dr-recovery` in `us-west-2`. Wait for both stacks to finish and allow EC2 bootstrap a few extra minutes. Open both printed HTTP URLs and confirm they show their actual role and region. In AWS Systems Manager, confirm the primary EC2 is an online managed node. If a stack fails, look at its CloudFormation Events and the instance's `/var/log/cloud-init-output.log` via permitted administrative access.

Then create the DNS stack, using your real domain/subdomain:

```powershell
.\demo.ps1 -Action deploy-dns -DomainName dr.example.com
.\demo.ps1 -Action status
```

Delegate that exact domain or subdomain to the name servers printed by the script, at the registrar or parent DNS provider. Avoid replacing existing domain records without understanding the effect. Public delegation can take time. Verify with `nslookup dr.example.com` and open `http://dr.example.com/`. If not delegated, direct `nslookup dr.example.com <one-printed-name-server>` tests the authoritative answer only; it doesn't prove ordinary browser resolution.

## Demonstrate actual failover

1. In Route 53, confirm *both* health checks are healthy. Query the name and open it; it should show Primary. Use a fresh DNS query and check the displayed page, not just the dashboard.
2. Submit `.\demo.ps1 -Action stop-primary`. This stops **Apache**, not the EC2 instance, using Systems Manager. Confirm the command succeeded in Systems Manager Run Command. It deliberately interrupts the primary website.
3. Watch the Route 53 primary health check until unhealthy. Query the authoritative server and, after DNS caches expire, the usual resolver. The answer should become the recovery IP and the browser should show Recovery. Detection and caching take time; do not promise a fixed duration. Existing connections are not moved.
4. Restore immediately with `.\demo.ps1 -Action start-primary`, confirm the command succeeded and check the primary HTTP endpoint. Route 53 returns to primary after it is healthy and caches refresh. If the command fails, use the AWS console's Systems Manager Run Command to start `httpd` or repair the instance.
5. Capture timestamps and actual results during your test. These indicate that single test's recovery time; they do not prove a guaranteed SLA or RPO.

If the secondary health check is unhealthy too, Route 53 behavior is not a guarantee of a working destination. Keep the primary service restorable and avoid claiming all failures are handled.

## Show a real backup, separately

The regional stacks each output a versioned S3 bucket. With a real local file and the primary bucket output, run `aws s3 cp .\sample.txt s3://YOUR-PRIMARY-BUCKET/demo/sample.txt --region us-east-1` then list it with `aws s3 ls s3://YOUR-PRIMARY-BUCKET/demo/ --region us-east-1`. This is an actual manual backup to S3, **not** automatic cross-region replication or application state recovery. Restoring and verifying the file requires an explicit download and comparison. Do not upload sensitive data for a demo.

## Cleanup after evaluation

Delete the DNS stack first, then each regional CloudFormation stack using the correct region. `BackupBucket` has `DeletionPolicy: Retain`, so the buckets and their contents remain and can continue to incur costs. Inspect and explicitly empty/delete only the demo buckets if no longer needed. Confirm EIPs and other billable resources are gone. Do not delete unrelated account resources. The scripts intentionally do not perform destructive cleanup automatically.
