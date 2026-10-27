CREATE DATABASE IF NOT EXISTS INSURANCE_DB;
CREATE SCHEMA IF NOT EXISTS INSURANCE_DB.BUSINESS_SCHEMA;
CREATE SCHEMA IF NOT EXISTS INSURANCE_DB.ANALYTICS_SCHEMA;

USE DATABASE INSURANCE_DB;
USE SCHEMA BUSINESS_SCHEMA;

-- Customers Reference Table
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id STRING PRIMARY KEY,
    full_name STRING,
    email STRING,
    phone STRING,
    dob DATE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Policies Reference Table
CREATE OR REPLACE TABLE POLICIES (
    policy_id STRING PRIMARY KEY,
    customer_id STRING REFERENCES CUSTOMERS(customer_id),
    policy_type STRING,
    coverage_limit NUMBER(10,2),
    deductible NUMBER(10,2),
    start_date DATE,
    expiration_date DATE,
    status STRING,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Raw Landing Table
CREATE OR REPLACE TABLE CLAIMS_MASTER (
    file_name STRING,
    raw_payload VARIANT,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Curated Analytics Adjudicated Table
CREATE OR REPLACE TABLE ANALYTICS_SCHEMA.ADJUDICATED_CLAIMS (
    claim_tracking_id STRING,
    patient_name STRING,
    account_number STRING,
    visit_date DATE,
    icd10_code STRING,
    total_amount NUMBER(10,2),
    adjudication_status STRING,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Seed Data Insertion
INSERT INTO CUSTOMERS VALUES 
    ('CUST-1004', 'Michael Brown', 'michael.b@example.com', '555-0104', '1982-04-12', CURRENT_TIMESTAMP()),
    ('CUST-1005', 'Emily Davis', 'emily.davis@example.com', '555-0105', '1995-08-25', CURRENT_TIMESTAMP()),
    ('CUST-1006', 'Daniel Wilson', 'dan.wilson@example.com', '555-0106', '1970-12-05', CURRENT_TIMESTAMP()),
    ('CUST-1012', 'William White', 'william.w@example.com', '555-0112', '1981-09-16', CURRENT_TIMESTAMP()),
    ('CUST-1013', 'Mia Harris', 'mia.harris@example.com', '555-0113', '1994-11-28', CURRENT_TIMESTAMP());

INSERT INTO POLICIES VALUES 
    ('POL-9994', 'CUST-1004', 'PREMIUM_HEALTH', 10000.00, 200.00, '2026-01-01', '2027-12-31', 'ACTIVE', CURRENT_TIMESTAMP()),
    ('POL-9995', 'CUST-1005', 'BASIC_HEALTH', 3000.00, 100.00, '2024-01-01', '2024-12-31', 'EXPIRED', CURRENT_TIMESTAMP()),
    ('POL-9996', 'CUST-1006', 'FAMILY_HEALTH', 20000.00, 350.00, '2025-06-01', '2027-05-31', 'ACTIVE', CURRENT_TIMESTAMP()),
    ('POL-10002', 'CUST-1012', 'FAMILY_HEALTH', 25000.00, 400.00, '2026-01-01', '2028-12-31', 'ACTIVE', CURRENT_TIMESTAMP()),
    ('POL-10003', 'CUST-1013', 'BASIC_HEALTH', 2000.00, 75.00, '2026-02-01', '2027-01-31', 'ACTIVE', CURRENT_TIMESTAMP());
