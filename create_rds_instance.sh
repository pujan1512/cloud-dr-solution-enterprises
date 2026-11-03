#!/usr/bin/env bash
# ==============================================================================
# Enterprise Disaster Recovery - RDS Primary Multi-AZ Database Provisioning
# Phase 1 / 50% Milestone Module: Database Infrastructure Setup
# ==============================================================================

DB_IDENTIFIER="enterprise-primary-db"
DB_CLASS="db.t3.micro"
DB_ENGINE="mysql"
ALLOCATED_STORAGE=20
MASTER_USER="dbadmin"
MASTER_PASS="EnterpriseDR2026!"
RETENTION_PERIOD=7
BACKUP_WINDOW="03:00-04:00"

echo "Creating Primary RDS MySQL Instance with Multi-AZ Disaster Recovery..."

aws rds create-db-instance \
    --db-instance-identifier "${DB_IDENTIFIER}" \
    --db-instance-class "${DB_CLASS}" \
    --engine "${DB_ENGINE}" \
    --engine-version "8.0" \
    --allocated-storage "${ALLOCATED_STORAGE}" \
    --storage-type gp3 \
    --master-username "${MASTER_USER}" \
    --master-user-password "${MASTER_PASS}" \
    --multi-az \
    --backup-retention-period "${RETENTION_PERIOD}" \
    --preferred-backup-window "${BACKUP_WINDOW}" \
    --storage-encrypted \
    --enable-performance-insights \
    --tags Key=DisasterRecoveryRole,Value=PrimaryDB Key=Environment,Value=Production

echo "RDS Instance ${DB_IDENTIFIER} creation initiated with Multi-AZ High Availability."
