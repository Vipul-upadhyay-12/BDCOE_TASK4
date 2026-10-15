import os
import io
import math
import json
import traceback
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from pydub import AudioSegment

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

# The single chosen lightweight, high-speed model
TARGET_LLM_MODEL = "openai/gpt-oss-120b"


def transcribe_audio_payload(audio_bytes: bytes, filename: str) -> str:
    """
    Transcribes audio using Groq Whisper.
    If the file exceeds 24 MB, it slices it into 10-minute audio chunks in-memory.
    """
    max_safe_bytes = 24 * 1024 * 1024

    # 1. Under limit: Direct transcription
    if len(audio_bytes) <= max_safe_bytes:
        transcription = client.audio.transcriptions.create(
            file=(filename or "lecture_audio.m4a", audio_bytes),
            model="whisper-large-v3-turbo",
            response_format="json",
        )
        return transcription.text.strip()

    # 2. Exceeds limit: Duration-based chunking via pydub
    print(f">>> File size ({len(audio_bytes) / (1024 * 1024):.2f} MB) exceeds 24MB. Chunking...")
    audio = AudioSegment.from_file(io.BytesIO(audio_bytes))

    chunk_length_ms = 10 * 60 * 1000  # 10 minutes
    total_chunks = math.ceil(len(audio) / chunk_length_ms)
    full_transcript = []

    for i in range(total_chunks):
        start_ms = i * chunk_length_ms
        end_ms = min((i + 1) * chunk_length_ms, len(audio))
        chunk = audio[start_ms:end_ms]

        buffer = io.BytesIO()
        chunk.export(buffer, format="mp3", bitrate="64k")
        chunk_bytes = buffer.getvalue()

        print(f">>> Transcribing chunk {i + 1}/{total_chunks}...")
        transcription = client.audio.transcriptions.create(
            file=(f"chunk_{i}.mp3", chunk_bytes),
            model="whisper-large-v3-turbo",
            response_format="json",
        )
        full_transcript.append(transcription.text.strip())

    return " ".join(full_transcript).strip()


@app.get("/")
def health_check():
    return {
        "status": "running",
        "api_key_configured": bool(api_key),
        "target_model": TARGET_LLM_MODEL
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
    text_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    num_questions: int = Form(5),
    difficulty: str = Form("Medium"),
    custom_prompt: Optional[str] = Form(None),
):
    try:
        raw_text_parts = []
        transcribed_content = ""

        # 1. Read uploaded .txt file if present
        if text_file:
            print(f">>> Received text file: {text_file.filename}")
            file_bytes = await text_file.read()
            decoded_text = file_bytes.decode("utf-8", errors="ignore").strip()
            if decoded_text:
                raw_text_parts.append(decoded_text)
                print(f">>> Extracted text file size: {len(decoded_text)} characters")

        # 2. Read direct form text field if present
        if text and text.strip():
            raw_text_parts.append(text.strip())

        # 3. Process audio track if present
        if audio_file:
            print(f">>> Received media file: {audio_file.filename}")
            audio_bytes = await audio_file.read()
            transcribed_content = transcribe_audio_payload(audio_bytes, audio_file.filename)
            print(f">>> Whisper Transcription Length: {len(transcribed_content)} characters")

        # 4. Combine context streams
        sections = []
        combined_text = "\n\n".join(raw_text_parts).strip()
        if combined_text:
            sections.append(f"=== DOCUMENT / SLIDE TEXT ===\n{combined_text}")
        if transcribed_content:
            sections.append(f"=== SPOKEN AUDIO TRANSCRIPT ===\n{transcribed_content}")

        context_text = "\n\n".join(sections).strip()

        if not context_text:
            raise HTTPException(
                status_code=400,
                detail="No readable document text or spoken audio provided."
            )

        # 5. Strict LLM prompt with exact question count enforcement
        # System instruction tuned to prevent JSON cutoff & escape crashes
        system_instruction = (
            "You are an expert academic assessment engine.\n"
            "You MUST respond ONLY with a single valid, well-formed JSON object matching this schema:\n"
            "{\n"
            '  "title": "string",\n'
            '  "notes": "string (concise markdown study summary, max 250 words)",\n'
            '  "quiz": [\n'
            "    {\n"
            '      "id": 1,\n'
            '      "question": "string",\n'
            '      "options": ["Option A", "Option B", "Option C", "Option D"],\n'
            '      "answer": "Option A",\n'
            '      "explanation": "string"\n'
            "    }\n"
            "  ]\n"
            "}\n\n"
            "STRICT FORMATTING RULES:\n"
            "1. Output valid JSON only. Do not wrap with markdown backticks (no ```json).\n"
            "2. Keep the 'notes' field concise (brief bullet points, high-yield definitions, max 250 words) to guarantee the quiz completes.\n"
            "3. MATH NOTATION: Use plain text or Unicode math (e.g., '2^2', 'x_1', '(az + b)/(cz + d)', 'z = x + iy'). NEVER use raw LaTeX backslashes like \\frac or \\lim as they break JSON string parsing.\n"
            f"4. The 'quiz' array MUST contain EXACTLY {num_questions} questions covering the provided syllabus."
        )

        user_content = f"""
REQUIRED QUESTIONS: {num_questions}
DIFFICULTY: {difficulty}
CUSTOM INSTRUCTIONS: {custom_prompt or "Generate high-yield questions covering the material."}

SOURCE MATERIAL:
---
{context_text}
---
"""

        print(f">>> Prompting {TARGET_LLM_MODEL} for {num_questions} questions...")

        completion = client.chat.completions.create(
            model=TARGET_LLM_MODEL,
            messages=[
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": user_content},
            ],
            response_format={"type": "json_object"},
            temperature=0.1,
            max_tokens=3000,  # Safe headroom without overflowing TPM
        )

        raw_output = completion.choices[0].message.content.strip()

        # Sanitize potential markdown codeblock wrappers
        if raw_output.startswith("```json"):
            raw_output = raw_output[7:]
        if raw_output.startswith("```"):
            raw_output = raw_output[3:]
        if raw_output.endswith("```"):
            raw_output = raw_output[:-3]

        parsed_data = json.loads(raw_output.strip())
        actual_questions = len(parsed_data.get("quiz", []))
        print(f">>> Successfully generated {actual_questions} questions.")

        return parsed_data

    except Exception as e:
        print(">>> BACKEND CRASH ERROR:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))