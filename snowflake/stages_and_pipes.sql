USE DATABASE INSURANCE_DB;
USE SCHEMA BUSINESS_SCHEMA;

-- Storage Integration for Secure S3 Access
CREATE OR REPLACE STORAGE INTEGRATION S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/SnowflakeS3AccessRole'
  STORAGE_ALLOWED_LOCATIONS = ('s3://health-claims-insurance-bucket/textract-output/');

-- External Stage
CREATE OR REPLACE STAGE S3_CLAIMS_STAGE
  URL = 's3://health-claims-insurance-bucket/textract-output/'
  STORAGE_INTEGRATION = S3_INTEGRATION
  FILE_FORMAT = (TYPE = JSON);

-- Snowpipe for Automated Ingestion
CREATE OR REPLACE PIPE CLAIMS_PIPE
  AUTO_INGEST = TRUE
  AS
  COPY INTO CLAIMS_MASTER (file_name, raw_payload)
  FROM (
      SELECT METADATA$FILENAME, $1
      FROM @S3_CLAIMS_STAGE
  );
