Intelligent Claims Adjudication OS
An enterprise-grade, decoupled medical claims processing and automated adjudication platform. This system combines serverless Python APIs, zero-shot multimodal AI extraction, AWS cloud storage, and an automated Snowflake Change Data Capture (CDC) pipeline to process unstructured receipts and execute real-time business rules without human intervention.

🏗️ System Architecture & Technology Stack
Plaintext
[ Streamlit UI ] ──(HTTP POST)──► [ AWS Lambda (FastAPI) ] ──► [ Gemini 2.5 Flash ]
                                                                      │
                                                                 (JSON Payload)
                                                                      ▼
                                                                [ AWS S3 Bucket ]
                                                                      │
                                                               (Direct Stage)
                                                                      ▼
                                                       [ Snowflake Data Cloud ]
                                                        ├── External Stage & Snowpipe
                                                        ├── RAW_SCHEMA (VARIANT JSON)
                                                        ├── Streams (CDC Delta Tracking)
                                                        ├── Tasks (Automated Rule Engine)
                                                        └── ANALYTICS_SCHEMA (Curated Output)
Core Technologies:
Frontend: Streamlit (Python UI for file uploads and real-time underwriter dashboards).

API Layer: FastAPI hosted on AWS Lambda / API Gateway.

Cognitive AI Engine: Gemini 2.5 Flash (Multimodal zero-shot receipt parsing with Pydantic schema enforcement).

Cloud Storage: AWS S3 (s3://health-claims-insurance-bucket/textract-output/).

Data Cloud & Engine: Snowflake (Storage Integrations, External Stages, Snowpipe, VARIANT semi-structured storage, CDC Streams, and automated Tasks).

🔄 End-to-End Execution Workflow
Document Upload: The user uploads a medical receipt (PNG, JPG, or PDF) via the Streamlit UI.

API Dispatch: Streamlit sends a multipart HTTP POST request to the FastAPI backend.

Multimodal Extraction: FastAPI forwards the raw image bytes to Gemini 2.5 Flash, which extracts key-value pairs (patient_name, account_number, visit_date, icd10_code, total_amount) and enforces a strict Pydantic JSON schema.

Cloud Persistence: FastAPI generates a unique tracking ID (UUID4) and writes the validated JSON object to AWS S3.

Snowflake Ingestion: Snowflake's External Stage and Snowpipe load the raw JSON object directly into the CLAIMS_MASTER table as semi-structured VARIANT data.

CDC Delta Tracking: A Snowflake Stream (CLAIMS_STREAM) monitors CLAIMS_MASTER and flags newly arrived micro-batches.

Automated Adjudication Task: A scheduled Snowflake Task (ADJUDICATE_CLAIMS_TASK) evaluates incoming claims against customer reference and active policy tables using a conditional business logic matrix.

Curated Analytics Output: The final adjudication status (AUTO_APPROVED, REJECTED_POLICY_INACTIVE, FLAGGED_EXCEEDS_LIMIT, or FLAGGED_UNMAPPED_CUSTOMER) is committed to the ADJUDICATED_CLAIMS analytics table and displayed instantly on the Streamlit underwriter dashboard.

📁 Repository Directory Structure
Plaintext
intelligent-claims-os/
├── README.md
├── requirements.txt
├── .env.example
├── backend/
│   └── main.py
├── frontend/
│   └── app.py
└── snowflake/
    ├── 01_setup_schema_and_tables.sql
    ├── 02_stages_and_pipes.sql
    └── 03_streams_and_tasks.sql
    
🚀 Installation & Setup Guide
1. Environment Configuration
Clone the repository and copy the example environment file:

Bash
cp .env.example .env
Fill in your credentials for AWS, Gemini AI, and Snowflake inside the .env file.

2. Snowflake Database Setup
Execute the SQL scripts in your Snowflake worksheet in exact sequential order:

snowflake/01_setup_schema_and_tables.sql — Creates databases, schemas, reference tables (CUSTOMERS, POLICIES), landing tables, and seed test data.

snowflake/02_stages_and_pipes.sql — Configures the AWS IAM Storage Integration, External Stage pointing to S3, and Snowpipe.

snowflake/03_streams_and_tasks.sql — Sets up Change Data Capture Streams and the automated Adjudication Task, then resumes the task engine.

3. Run the Backend API
Install dependencies and launch the FastAPI server:

Bash
pip install -r requirements.txt
python backend/main.py
4. Run the Frontend Dashboard
In a separate terminal window, launch the Streamlit interface:

Bash
streamlit run frontend/app.py
