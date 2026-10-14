import os
import json
import traceback
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq

app = FastAPI(title="ToolForge API")

# Setup CORS for mobile and web requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Read API key directly from environment variables
api_key = os.getenv("GROQ_API_KEY")
client = Groq(api_key=api_key)


@app.get("/")
def health_check():
    return {
        "status": "running",
        "api_key_configured": bool(api_key)
    }


@app.get("/check-models")
def check_models():
    current_key = os.getenv("GROQ_API_KEY")
    if not current_key:
        return {
            "status": "error",
            "message": "GROQ_API_KEY environment variable is missing or empty."
        }
    try:
        models = client.models.list()
        return {
            "status": "connected",
            "key_prefix": current_key[:8] + "...",
            "available_models": [m.id for m in models.data]
        }
    except Exception as e:
        return {
            "status": "auth_or_groq_error",
            "key_prefix": current_key[:8] + "...",
            "error": str(e)
        }


@app.post("/generate-quiz")
@app.post("/generate-quiz/")
async def generate_quiz(
    text: Optional[str] = Form(None),
    audio_file: Optional[UploadFile] = File(None),
    num_questions: int = Form(5),
    difficulty: str = Form("Medium"),
    custom_prompt: Optional[str] = Form(None),
):
    try:
        context_text = ""

        # 1. Extracted Text Handling (e.g., from PDF OCR or TXT)
        if text and text.strip():
            context_text = text.strip()
            print(f">>> Received text from client. Length: {len(context_text)} characters")

        # 2. Media / Audio Handling (Whisper Transcription)
        elif audio_file:
            print(f">>> Received media file: {audio_file.filename}")
            audio_bytes = await audio_file.read()
            
            transcription = client.audio.transcriptions.create(
                file=(audio_file.filename or "media.mp3", audio_bytes),
                model="whisper-large-v3",
                response_format="json",
            )
            context_text = transcription.text
            print(f">>> Audio transcribed. Length: {len(context_text)} characters")

        if not context_text or not context_text.strip():
            raise HTTPException(
                status_code=400, 
                detail="No readable text or audio content provided."
            )

        # 3. LLM Prompt Construction
        system_instruction = (
            "You are an assessment engine. You MUST respond ONLY with valid JSON matching this schema:\n"
            "{\n"
            '  "title": "string",\n'
            '  "notes": "string (summary in markdown)",\n'
            '  "quiz": [\n'
            "    {\n"
            '      "id": 1,\n'
            '      "question": "string",\n'
            '      "options": ["Option A", "Option B", "Option C", "Option D"],\n'
            '      "answer": "Option A",\n'
            '      "explanation": "string"\n'
            "    }\n"
            "  ]\n"
            "}"
        )

        user_content = f"""
Number of Questions: {num_questions}
Target Difficulty: {difficulty}
Custom Instructions: {custom_prompt or "Focus on core concepts."}

Source Content:
---
{context_text[:12000]}
---
"""

        # Model fallback chain
        candidate_models = [
            "llama-3.1-8b-instant",
            "openai/gpt-oss-20b",
            "llama-3.3-70b-versatile",
            "llama3-8b-8192",
        ]

        completion = None
        last_exception = None

        for model_id in candidate_models:
            try:
                print(f">>> Attempting generation with model: {model_id}")
                completion = client.chat.completions.create(
                    model=model_id,
                    messages=[
                        {"role": "system", "content": system_instruction},
                        {"role": "user", "content": user_content},
                    ],
                    response_format={"type": "json_object"},
                    temperature=0.2,
                )
                print(f">>> Successfully generated using: {model_id}")
                break
            except Exception as err:
                print(f">>> Model {model_id} failed: {err}")
                last_exception = err

        if completion is None:
            raise last_exception or Exception("All candidate models failed to execute.")

        raw_output = completion.choices[0].message.content.strip()

        # Sanitize potential markdown wrappers
        if raw_output.startswith("```json"):
            raw_output = raw_output[7:]
        if raw_output.startswith("```"):
            raw_output = raw_output[3:]
        if raw_output.endswith("```"):
            raw_output = raw_output[:-3]

        return json.loads(raw_output.strip())

    except Exception as e:
        print(">>> BACKEND CRASH ERROR:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))