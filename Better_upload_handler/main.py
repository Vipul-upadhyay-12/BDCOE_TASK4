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


def transcribe_audio_payload(audio_bytes: bytes, filename: str) -> str:
    """
    Transcribes audio using Groq Whisper.
    If the file exceeds 24 MB, it safely slices it into 10-minute audio chunks in-memory.
    """
    max_safe_bytes = 24 * 1024 * 1024

    # 1. Under limit: Direct transcription
    if len(audio_bytes) <= max_safe_bytes:
        transcription = client.audio.transcriptions.create(
            file=(filename or "lecture_audio.aac", audio_bytes),
            model="whisper-large-v3-turbo",
            response_format="json",
        )
        return transcription.text.strip()

    # 2. Exceeds limit: Duration-based chunking via pydub
    print(f">>> File size ({len(audio_bytes) / (1024 * 1024):.2f} MB) exceeds 24MB. Chunking...")
    audio = AudioSegment.from_file(io.BytesIO(audio_bytes))

    # 10 minutes in milliseconds
    chunk_length_ms = 10 * 60 * 1000
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
        ocr_content = (text or "").strip()
        transcribed_content = ""

        # 1. Spoken Audio Handling (Whisper)
        if audio_file:
            print(f">>> Received media file: {audio_file.filename}")
            audio_bytes = await audio_file.read()
            transcribed_content = transcribe_audio_payload(audio_bytes, audio_file.filename)
            print(f">>> Whisper Transcription Length: {len(transcribed_content)} characters")

        # 2. Assemble context from both streams
        sections = []
        if ocr_content:
            print(f">>> Received OCR text. Length: {len(ocr_content)} characters")
            sections.append(f"=== ON-SCREEN SLIDES & TEXT (VISUAL OCR) ===\n{ocr_content}")
        if transcribed_content:
            sections.append(f"=== SPOKEN LECTURE / AUDIO TRANSCRIPT ===\n{transcribed_content}")

        context_text = "\n\n".join(sections).strip()

        if not context_text:
            raise HTTPException(
                status_code=400,
                detail="No readable slide text or spoken audio provided."
            )

        # 3. LLM Prompt Construction
        system_instruction = (
            "You are an expert academic tutor and assessment engine. "
            "You MUST respond ONLY with a single valid JSON object matching this schema:\n"
            "{\n"
            '  "title": "string",\n'
            '  "notes": "string (comprehensive, detailed study guide in markdown)",\n'
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
            "CRITICAL INSTRUCTIONS FOR AUDIO & SLIDES:\n"
            "1. If the audio transcription contains song lyrics, background music, or casual chatter instead of educational material, IGNORE the audio and rely completely on the ON-SCREEN SLIDES to generate notes and quiz questions.\n"
            "2. If educational audio and visual slides complement each other, synthesize them together.\n"
            "3. Structure the 'notes' field exhaustively: use Markdown headings (##, ###), bold key terminology, detailed bullet points, core definitions, and step-by-step explanations."
        )

        user_content = f"""
Number of Questions: {num_questions}
Target Difficulty: {difficulty}
Custom Instructions: {custom_prompt or "Provide exhaustive, high-yield notes and testing questions."}

Source Content:
---
{context_text[:14000]}
---
"""

        # Priority models verified for your key
        candidate_models = [
            "openai/gpt-oss-20b",
            "openai/gpt-oss-120b",
            "qwen/qwen3.8-27b",
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
                    temperature=0.3,
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