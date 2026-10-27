import streamlit as st
import requests
import snowflake.connector
import pandas as pd
import os

st.set_page_config(page_title="Intelligent Claims Adjudication OS", layout="wide")

st.title("🛡️ Intelligent Claims Adjudication OS")
st.markdown("Automated medical receipt ingestion, AI extraction, and Snowflake-powered rule adjudication.")

# Sidebar Navigation
tab = st.sidebar.radio("Navigation", ["Upload Claim Receipt", "Underwriter Audit Dashboard"])

API_URL = os.getenv("FASTAPI_URL", "http://localhost:8000/extract-claim")

def get_snowflake_connection():
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
        database=os.getenv("SNOWFLAKE_DATABASE", "INSURANCE_DB"),
        schema=os.getenv("SNOWFLAKE_SCHEMA", "BUSINESS_SCHEMA")
    )

if tab == "Upload Claim Receipt":
    st.header("Upload Medical Receipt")
    uploaded_file = st.file_uploader("Choose a receipt image or PDF", type=["png", "jpg", "jpeg", "pdf"])
    
    if uploaded_file and st.button("Process & Adjudicate Claim"):
        with st.spinner("Analyzing receipt with Gemini 2.5 Flash & storing to S3..."):
            files = {"file": (uploaded_file.name, uploaded_file.getvalue(), uploaded_file.type)}
            try:
                response = requests.post(API_URL, files=files)
                if response.status_code == 200:
                    res_data = response.json()
                    st.success(f"Claim successfully processed! ID: {res_data['claim_tracking_id']}")
                    st.json(res_data["extracted_payload"])
                else:
                    st.error(f"Error: {response.text}")
            except Exception as e:
                st.error(f"Connection failed: {e}")

elif tab == "Underwriter Audit Dashboard":
    st.header("Real-Time Adjudicated Claims Audit")
    if st.button("Refresh Dashboard Data"):
        try:
            conn = get_snowflake_connection()
            query = "SELECT * FROM ANALYTICS_SCHEMA.ADJUDICATED_CLAIMS ORDER BY processed_at DESC LIMIT 50;"
            df = pd.read_sql(query, conn)
            conn.close()
            
            st.metric(label="Total Adjudicated Claims", value=len(df))
            st.dataframe(df, use_container_width=True)
        except Exception as e:
            st.warning(f"Could not connect to Snowflake: {e}")
            st.info("Ensure Snowflake environment variables are properly configured.")
