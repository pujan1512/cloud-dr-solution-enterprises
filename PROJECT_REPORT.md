# Cloud disaster recovery: project status and viva guide

## What is ready

The supported live demonstration is in `live_demo/`. It defines two regional EC2 HTTP servers, separate S3 backup buckets, and Route 53 health-check-based DNS failover. The scripts deploy and operate AWS resources through the AWS CLI. This is prepared for deployment, **not verified live** until valid AWS credentials, account permissions, region capacity, and a suitable domain/delegation are provided and the actual drill succeeds. Follow `live_demo/README.md`.

The original repository contains a browser simulation and other experimental code. It must not be presented as proof that AWS resources, database recovery, replication or reconciliation are working. The prior README contained unsupported claims, including hard-coded performance figures and production readiness.

## Actual proposed live chain

1. One CloudFormation regional stack in `us-east-1` and another in `us-west-2` each creates a VPC, public subnet, internet route, security group, EC2 instance, Elastic IP, Systems Manager role and versioned S3 bucket.
2. EC2 user data installs Apache, creates a page identifying the instance's role and region, and creates `/health`.
3. A Route 53 stack creates a hosted zone, health checks against both EC2 addresses, and primary/secondary failover A records. A registrar or parent DNS zone must delegate a domain/subdomain to the new zone before ordinary public DNS resolution works.
4. The DNS resolver receives an address from Route 53; the browser then connects directly to the selected web server. Route 53 changes DNS answers, not existing connections.
5. The demonstration submits an AWS Systems Manager command to stop Apache on the primary. After health detection and DNS cache expiry, new lookups can receive the recovery address. Another command starts Apache again. Verify the command status and endpoint response; submission alone is not proof of completion.
6. S3 uploads are manual and separate. The two buckets do not replicate or back up the EC2 page automatically. This demonstration does not transfer database writes, claim zero data loss, or calculate a real RPO.

Both servers run continuously, so they cost money even when the recovery server is idle. Pilot-light/stopped alternatives reduce some compute costs but need start/readiness orchestration and have longer recovery. Route 53 hosted zone, health checks, public IPv4, EBS, S3 and other services can also cost money. The demo uses public HTTP for easy visibility; do not use for confidential information.

## File-by-file guide

### Supported live demo (new)

- `live_demo/regional.yaml`: CloudFormation template for one regional network, EC2 server, EIP, SSM permissions and versioned private S3 bucket. Deploy once per region with a different `SiteRole`.
- `live_demo/dns.yaml`: Route 53 hosted zone, primary and recovery HTTP health checks, and failover A records, with 60-second TTL.
- `live_demo/demo.ps1`: deploys regional or DNS stacks, reads stack status and submits SSM commands to stop/start Apache for the drill. It does not itself verify that submitted commands succeeded.
- `live_demo/README.md`: prerequisites, costs, deployment, actual drill, manual S3 backup and cleanup instructions.
- `live_demo/test_local.ps1`: exercises deployment and stop/start command construction with mocked AWS responses; it never tests real AWS.

### Original presentation and simulation

- `README.md`: updated project entry point explaining the live demo and simulation boundary.
- `README-legacy.md`: original project overview, retained for reference; its readiness and benchmark claims are not verified.
- `project_runner.html`: presentation and documentation launch page; not a backend service.
- `open_dashboard.bat`: opens the browser dashboard locally.
- `run_simulation.bat`: launches the terminal simulator.
- `simulation/dr_dashboard.html`: interactive client-side simulation of outages, writes, sync and failback; it does not control the AWS resources.
- `simulation/simulate_dr.py`: terminal narrative/simulator; timing and results are simulated.
- `verify_dr_solution.py`: legacy checks; some check file presence and simulated results and cannot prove real AWS recovery. It can write a chaos report and may attempt AWS calls.

### Original AWS infrastructure and networking prototypes

- `cloudformation/primary_region.yaml`: older primary VPC, EC2, MySQL RDS and S3 template; not the regional template used by the new demo. It includes an embedded default database password and open SSH, and requires review before deployment.
- `cloudformation/dr_region.yaml`: older DR VPC, EC2, S3 and recovery-role template; does not by itself create a cross-region database replica.
- `cloud_dr_resources.yaml`: older consolidated infrastructure template, using an AMI requiring review.
- `networking/route53_advanced_routing.yaml`: older Route 53 template with health checks and failover records; its `/health` endpoint and alarm-to-Lambda integration are not established by the older regional templates.
- `create_route53_health_check.sh`: older AWS CLI script for Route 53 health check and DNS record creation; default values are examples, and it can simulate output when CLI is missing.
- `create_rds_instance.sh`: older CLI script for RDS creation; inspect configuration and costs before use.

### Original recovery and backup prototypes

- `lambda/lambda_failover_handler.py`: recovery handler with conditional AWS calls and simulated fallback; the database promotion log is not a real promotion.
- `lambda_start_ec2.py`: older start-instance Lambda example; can return simulation output after AWS errors.
- `backup_to_s3.sh`: older root backup script; review its settings before use.
- `backup_automation/backup_to_s3.sh`: archives local files and attempts AWS CLI S3 upload, with a simulated path if CLI is absent. It is not the new demo's automatic replication system.
- `backup_automation/backup_manager.py`: example backup status auditor; replication-verification result is hard-coded and the fallback uses simulated metadata.
- `backup_automation/rds_snapshot_dr.sh`: older example for cross-region RDS snapshot operations; not wired into the supported live demo.
- `failback_automation/reverse_delta_sync.py`: simulated transaction and object reconciliation; it does not execute the claimed transfers.
- `failback_automation/failback_orchestrator.sh`: older failback orchestration prototype, not verified as a complete live failback system.

### Original monitoring, chaos, data and alerts

- `monitoring/cloudwatch_canary.py`: simulated endpoint monitoring; not proof of a deployed CloudWatch Synthetics canary.
- `chaos_engineering/chaos_monkey_dr.py`: returns simulated experiment outcomes and writes a report; does not demonstrate fault injection against AWS.
- `chaos_engineering/chaos_resilience_report.json`: report artifact from the simulator, not a measurement of live resilience.
- `alerting/notification_service.py`: notification prototype with simulated behavior; examine and configure before claiming real delivery.
- `alerting/incident_post_mortem.md`: example incident report; not evidence a real incident occurred.
- `database/seed_enterprise_data.sql`: example relational schema and seed data; the new static web demo does not use it.
- `.gitignore`: lists local/generated files Git should ignore; not part of the recovery system.

## What to say in evaluation

“Our working scope is a cross-region EC2 and Route 53 DNS failover demonstration, plus a separate manual S3 backup example. CloudFormation describes infrastructure, Systems Manager allows us to stop and restore the primary web service, and Route 53 uses health checks to select DNS answers. We do not yet claim database failover, automatic replication, zero data loss, measured RPO or a production SLA.”

Say this only after deploying and actually verifying the chain. If AWS access is still unavailable, describe the live infrastructure as deployment-ready but unverified and use the local simulation only as a simulation.


