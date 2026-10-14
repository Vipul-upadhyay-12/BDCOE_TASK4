import os
import json
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq

app = FastAPI(title="ToolForge API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

@app.get("/")
def health_check():
    return {"status": "running", "mode": "client-side-extraction"}

@app.post("/generate-quiz")
async def generate_quiz(
    text: Optional[str] = Form(None),
    audio_file: Optional[UploadFile] = File(None),
    num_questions: int = Form(5),
    difficulty: str = Form("Medium"),
    custom_prompt: Optional[str] = Form(None),
):
    context_text = ""

    # 1. Direct text extracted from client (PDF OCR, Plain Text)
    if text and text.strip():
        context_text = text.strip()

    # 2. Audio extracted from client (Video stripped locally, or raw audio)
    elif audio_file:
        audio_bytes = await audio_file.read()
        transcription = client.audio.transcriptions.create(
            file=("audio.mp3", audio_bytes),
            model="whisper-large-v3",
            response_format="json",
        )
        context_text = transcription.text

    if not context_text or not context_text.strip():
        raise HTTPException(status_code=400, detail="No readable content received.")

    # 3. Llama 3.1 Inference on Groq LPU (~1.5 to 2.5s)
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

    completion = client.chat.completions.create(
        messages=[
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": user_content},
        ],
        model="llama-3.3-70b-versatile",
        response_format={"type": "json_object"},
        temperature=0.2,
    )

    return json.loads(completion.choices[0].message.content)