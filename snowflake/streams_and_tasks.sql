USE DATABASE INSURANCE_DB;
USE SCHEMA BUSINESS_SCHEMA;

-- CDC Stream on Raw Claims
CREATE OR REPLACE STREAM CLAIMS_STREAM ON TABLE CLAIMS_MASTER;

-- Automated Adjudication Task
CREATE OR REPLACE TASK ADJUDICATE_CLAIMS_TASK
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '1 minute'
  WHEN SYSTEM$STREAM_HAS_DATA('CLAIMS_STREAM')
AS
INSERT INTO INSURANCE_DB.ANALYTICS_SCHEMA.ADJUDICATED_CLAIMS
SELECT 
    s.raw_payload:claim_tracking_id::STRING AS claim_tracking_id,
    s.raw_payload:patient_name::STRING AS patient_name,
    s.raw_payload:account_number::STRING AS account_number,
    s.raw_payload:visit_date::DATE AS visit_date,
    s.raw_payload:icd10_code::STRING AS icd10_code,
    s.raw_payload:total_amount::NUMBER(10,2) AS total_amount,
    CASE 
        WHEN c.customer_id IS NULL THEN 'FLAGGED_UNMAPPED_CUSTOMER'
        WHEN p.status != 'ACTIVE' OR s.raw_payload:visit_date::DATE > p.expiration_date THEN 'REJECTED_POLICY_INACTIVE'
        WHEN s.raw_payload:total_amount::NUMBER(10,2) > p.coverage_limit THEN 'FLAGGED_EXCEEDS_LIMIT'
        ELSE 'AUTO_APPROVED'
    END AS adjudication_status,
    CURRENT_TIMESTAMP() AS processed_at
FROM CLAIMS_STREAM s
LEFT JOIN CUSTOMERS c 
  ON LOWER(TRIM(s.raw_payload:patient_name::STRING)) = LOWER(TRIM(c.full_name))
LEFT JOIN POLICIES p 
  ON c.customer_id = p.customer_id;

-- Resume the Task
ALTER TASK ADJUDICATE_CLAIMS_TASK RESUME;
