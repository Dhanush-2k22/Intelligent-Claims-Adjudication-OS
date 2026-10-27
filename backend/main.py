import os
import uuid
import json
import boto3
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

app = FastAPI(title="Intelligent Claims Adjudication API", version="1.0")

# Initialize Clients
s3_client = boto3.client(
    "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_REGION", "us-east-1")
)

# Initialize Gemini Client using official Google GenAI SDK
ai_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
S3_BUCKET = os.getenv("S3_BUCKET_NAME", "health-claims-insurance-bucket")


class ClaimExtractionSchema(BaseModel):
    patient_name: str = Field(description="Full name of the patient billed")
    account_number: str = Field(description="Account or receipt number")
    visit_date: str = Field(description="Date of visit in YYYY-MM-DD format")
    icd10_code: str = Field(description="Primary ICD-10 diagnostic code")
    total_amount: float = Field(description="Final balance due numerical value")


@app.post("/extract-claim")
async def extract_claim(file: UploadFile = File(...)):
    try:
        file_bytes = await file.read()
        
        # Call Gemini 2.5 Flash for Multimodal Zero-Shot Extraction
        prompt = (
            "Extract the medical receipt details accurately into the requested JSON schema. "
            "Ensure the total_amount is parsed as a float and visit_date as YYYY-MM-DD."
        )
        
        response = ai_client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[
                types.Part.from_bytes(data=file_bytes, mime_type=file.content_type),
                prompt
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ClaimExtractionSchema,
                temperature=0.0
            ),
        )
        
        extracted_data = json.loads(response.text)
        
        # Assign unique tracking ID and S3 path
        claim_id = f"claim_{uuid.uuid4().hex[:8]}"
        extracted_data["claim_tracking_id"] = claim_id
        
        # Write JSON payload to AWS S3
        s3_key = f"textract-output/{claim_id}.json"
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=json.dumps(extracted_data),
            ContentType="application/json"
        )
        
        return {
            "status": "success",
            "claim_tracking_id": claim_id,
            "s3_path": f"s3://{S3_BUCKET}/{s3_key}",
            "extracted_payload": extracted_data
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
