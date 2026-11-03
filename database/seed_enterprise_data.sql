-- ==============================================================================
-- Enterprise Disaster Recovery - Sample Relational Seed Data
-- Demonstrates transactional business data backed up and verified during DR
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS enterprise_corp;
USE enterprise_corp;

-- 1. Customers Table
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(120) NOT NULL,
    contact_email VARCHAR(100) NOT NULL,
    account_tier ENUM('Standard', 'Premium', 'MissionCritical') DEFAULT 'Standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Financial Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status ENUM('PENDING', 'COMPLETED', 'FAILED') DEFAULT 'COMPLETED',
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 3. Disaster Recovery Replication Audit Log
CREATE TABLE IF NOT EXISTS dr_replication_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    source_region VARCHAR(32) NOT NULL,
    destination_region VARCHAR(32) NOT NULL,
    last_synced_transaction_id INT NOT NULL,
    sync_status ENUM('SYNCHRONIZED', 'LAGGING', 'FAILED') DEFAULT 'SYNCHRONIZED',
    sync_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed Sample Customers
INSERT INTO customers (company_name, contact_email, account_tier) VALUES
('Acme Global Logistics', 'ops@acmeglobal.com', 'MissionCritical'),
('Apex Financial Holdings', 'dr-team@apexfin.com', 'MissionCritical'),
('HealthPulse Systems', 'sysadmin@healthpulse.org', 'Premium'),
('Nexus Cloud Retail', 'devops@nexuscloud.io', 'Standard');

-- Seed Sample Transactions
INSERT INTO transactions (customer_id, amount, currency, status) VALUES
(1, 45200.00, 'USD', 'COMPLETED'),
(2, 128900.50, 'USD', 'COMPLETED'),
(1, 1530.25, 'USD', 'COMPLETED'),
(3, 8940.00, 'USD', 'COMPLETED'),
(4, 450.00, 'USD', 'COMPLETED');

-- Seed Disaster Recovery Checkpoint
INSERT INTO dr_replication_audit (source_region, destination_region, last_synced_transaction_id, sync_status) VALUES
('us-east-1 (N. Virginia)', 'us-west-2 (Oregon)', 5, 'SYNCHRONIZED');
