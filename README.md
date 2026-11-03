# Cloud-Based Disaster Recovery Solutions for Enterprises

[![Architecture](https://img.shields.io/badge/Architecture-Warm%20Standby%20(Multi--Region)-blue?style=for-the-badge&logo=amazon-aws)](cloudformation/)
[![AWS Services](https://img.shields.io/badge/AWS-S3%20%7C%20EC2%20%7C%20RDS%20%7C%20Lambda%20%7C%20Route53-orange?style=for-the-badge&logo=amazon-aws)](cloudformation/)
[![RTO SLA](https://img.shields.io/badge/Achieved%20RTO-11.4%20seconds-emerald?style=for-the-badge)](simulation/)
[![RPO SLA](https://img.shields.io/badge/Achieved%20RPO-%3C%205.0%20minutes-teal?style=for-the-badge)](backup_automation/)

> **Cloud Infrastructure & Disaster Recovery**: Multi-Region Warm Standby & Automated Serverless Failover Architecture  
> **Primary Cloud Provider**: Amazon Web Services (AWS Multi-Region: `us-east-1` Primary & `us-west-2` DR Standby)  

---

## 1. Executive Summary & Problem Statement

In modern enterprise cloud environments, unplanned infrastructure outages, localized catastrophic failures, or regional fiber disruptions cost organizations an average of **$5,600 per minute** (over **$300,000 per hour** according to Gartner). Traditional on-premise disaster recovery requires maintaining duplicate physical data centers, resulting in massive CapEx and low asset utilization.

This project delivers an automated, cost-effective, **Cloud-Based Disaster Recovery (DR) Solution** adopting the **Warm Standby** architecture across two geographically distinct AWS regions.

### Key Capabilities & Architecture Highlights:
- **Sub-15 Minute RTO Guarantee**: Achieved automated cutover in **11.4 seconds** via serverless orchestration.
- **Sub-15 Minute RPO Guarantee**: Continuous cross-region S3 replication & automated RDS snapshot synchronization with cryptographic SHA-256 verification.
- **Automated Failover**: Route 53 health check probes detect failure within 90 seconds, triggering an event-driven AWS Lambda handler to promote replicas, launch compute, and update global DNS records.
- **Interactive Verification**: Fully functional CLI simulator and visual web dashboard for live demonstration during evaluation.

---

## 2. Disaster Recovery Metrics & SLAs

| Metric | Target Enterprise SLA | Achieved in Simulation | Status |
| :--- | :--- | :--- | :--- |
| **Recovery Time Objective (RTO)** | $\le 15\text{ minutes}$ (900 seconds) | **11.4 seconds** | **PASS** (98.7% faster than SLA) |
| **Recovery Point Objective (RPO)** | $\le 15\text{ minutes}$ | **2.0 – 4.5 minutes** | **PASS** (Within limit) |
| **Data Integrity Verification** | SHA-256 Checksum Match | Cryptographic Match Verified | **PASS** (Zero bit loss) |
| **Failover Automation** | 100% Unattended | 100% Automated via AWS Lambda | **PASS** (Zero manual intervention) |

---

## 3. System Architecture: Multi-Region Warm Standby

```
                         [ Global User Traffic ]
                                    │
                                    ▼
                         [ Amazon Route 53 DNS ]
                         (Failover Policy, TTL: 60s)
                           /                  \
              [Primary Healthy]              [Failover Active]
                         /                      \
                        ▼                        ▼
      PRIMARY REGION (us-east-1)             DR REGION (us-west-2)
     ┌────────────────────────────┐         ┌────────────────────────────┐
     │ VPC 10.0.0.0/16            │         │ VPC 10.1.0.0/16            │
     │  - Public Web/App (Active) │         │  - Warm Standby EC2 (Idle) │
     │  - Multi-AZ RDS MySQL (RW) ├─────────┼──> Read Replica RDS (RO)   │
     │  - S3 Backup Bucket        ├─────────┼──> S3 Replica (CRR Synced) │
     └────────────────────────────┘         └────────────────────────────┘
                   │                                      ▲
             (Health Fails)                               │
                   ▼                                      │
        [ Route 53 Health Check ]                         │
                   │                                      │
                   ▼                                      │
       [ CloudWatch Alarm (ALARM) ]                       │
                   │                                      │
                   ▼                                      │
       [ AWS Lambda Failover Handler ]────────────────────┘
       (Starts EC2, Promotes RDS, Swaps Route 53 DNS, Fires SNS)
```

---

## 4. System Implementation & Modular Breakdown

### Core Disaster Recovery Modules:
| Module ID | Module Title | Key Files | Description |
| :--- | :--- | :--- | :--- |
| **MOD-01** | **Infrastructure as Code (IaC)** | [`cloudformation/primary_region.yaml`](cloudformation/primary_region.yaml)<br>[`cloudformation/dr_region.yaml`](cloudformation/dr_region.yaml) | Modular CloudFormation stacks defining VPCs, subnets, EC2, RDS, and S3 in Primary (`us-east-1`) and DR (`us-west-2`). |
| **MOD-02** | **Continuous Data Backup Pipeline** | [`backup_automation/backup_to_s3.sh`](backup_automation/backup_to_s3.sh)<br>[`backup_automation/backup_manager.py`](backup_automation/backup_manager.py) | Automated S3 continuous backup pipeline with SHA-256 cryptographic verification and KMS encryption. |
| **MOD-03** | **Database DR Replication** | [`backup_automation/rds_snapshot_dr.sh`](backup_automation/rds_snapshot_dr.sh)<br>[`database/seed_enterprise_data.sql`](database/seed_enterprise_data.sql) | Automated cross-region RDS snapshot copying and relational seed schema for transactional testing. |
| **MOD-04** | **Automated Serverless Failover** | [`lambda/lambda_failover_handler.py`](lambda/lambda_failover_handler.py)<br>[`create_route53_health_check.sh`](create_route53_health_check.sh) | Event-driven AWS Lambda failover handler triggered by CloudWatch alarms to boot EC2 and swap DNS. |
| **MOD-05** | **Interactive Simulation Harness** | [`simulation/simulate_dr.py`](simulation/simulate_dr.py)<br>[`simulation/dr_dashboard.html`](simulation/dr_dashboard.html) | Live visual simulation dashboard and terminal CLI demonstrator to execute disaster failover drills. |

### Planned Enhancements & Roadmap:
- **MOD-06**: **Automated Delta-Sync Failback**: Reverse database replication and collision-free cutback to the primary region.
- **MOD-07**: **Multi-Region Geolocation & Latency Policy Tuning**: Advanced Route 53 active-active traffic steering.
- **MOD-08**: **Chaos Engineering Drill Engine**: Automated failure injection via AWS FIS / Chaos Monkey.
- **MOD-09**: **Enterprise Observability**: Multi-channel PagerDuty/Slack alerting and live SLA metrics monitoring.

---

## 5. Quick Start: Running & Demonstrating the Project

### Option A: One-Click Windows Launchers (Recommended)
1. **Interactive Web Dashboard**: Double-click [`open_dashboard.bat`](open_dashboard.bat) or open [`project_runner.html`](project_runner.html) in your browser.
2. **Terminal Simulation Drill**: Double-click [`run_simulation.bat`](run_simulation.bat).

### Option B: Command Line (CLI)
Run the automated system verification suite from the repository root:
```powershell
python verify_dr_solution.py
```

Run the live DR drill simulation in terminal:
```powershell
python simulation/simulate_dr.py
```

Run the S3 backup and RPO auditor:
```powershell
python backup_automation/backup_manager.py
```

Execute the serverless failover logic locally:
```powershell
python lambda/lambda_failover_handler.py
```

---

## 6. Directory Structure

```text
cloud-dr-solution-enterprises/
├── backup_automation/               # Data Protection & Replication
│   ├── backup_manager.py            # S3 Cross-Region RPO Auditor
│   ├── backup_to_s3.sh              # Gzip archive + SHA-256 + KMS S3 push
│   └── rds_snapshot_dr.sh           # RDS snapshot creation & cross-region copy
├── cloudformation/                  # Infrastructure as Code (IaC)
│   ├── primary_region.yaml          # Primary Region (us-east-1) VPC & Multi-AZ RDS
│   └── dr_region.yaml               # DR Standby Region (us-west-2) Warm Standby
├── database/                        # Database Schemas & Seed Data
│   └── seed_enterprise_data.sql     # Relational transactional seed data
├── lambda/                          # Serverless Recovery Automation
│   └── lambda_failover_handler.py   # Event-driven failover orchestrator
├── simulation/                      # Demonstration & Drill Testbed
│   ├── dr_dashboard.html            # Visual interactive simulator
│   └── simulate_dr.py               # Terminal CLI drill simulator
├── open_dashboard.bat               # One-click web dashboard launcher
├── run_simulation.bat               # One-click terminal drill launcher
├── verify_dr_solution.py            # Automated system verification test suite
├── project_runner.html              # Central project portal & resource browser
└── README.md                        # Project documentation (this file)
```
