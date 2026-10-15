import os
import tempfile
import json
import traceback
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

api_key = os.getenv("GROQ_API_KEY")
client = Groq(api_key=api_key)

TARGET_LLM_MODEL = "openai/gpt-oss-20b"
WHISPER_MODEL = "whisper-large-v3-turbo"


def transcribe_single_pass(audio_path: str) -> str:
    """
    Direct single-pass transcription.
    Takes 3-5 seconds on Groq Whisper for files under 25 MB.
    """
    print(f">>> Transcribing audio file directly ({os.path.getsize(audio_path) / (1024 * 1024):.2f} MB)...")
    with open(audio_path, "rb") as f:
        transcription = client.audio.transcriptions.create(
            file=(os.path.basename(audio_path), f),
            model=WHISPER_MODEL,
            response_format="json",
        )
    return transcription.text.strip()


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
    temp_audio_path = None
    try:
        raw_text_parts = []
        transcribed_content = ""

        # 1. Read OCR/Slides Text (< 5 ms)
        if text_file:
            content_bytes = await text_file.read()
            decoded = content_bytes.decode("utf-8", errors="ignore").strip()
            if decoded:
                raw_text_parts.append(decoded)

        if text and text.strip():
            raw_text_parts.append(text.strip())

        # 2. Transcribe Audio (Single pass: 3-5 seconds)
        if audio_file:
            suffix = os.path.splitext(audio_file.filename or "")[1] or ".m4a"
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                temp_audio_path = tmp.name
                # Stream file to disk chunk-by-chunk to keep Render RAM under 20 MB
                while chunk := await audio_file.read(1024 * 1024):
                    tmp.write(chunk)

            transcribed_content = transcribe_single_pass(temp_audio_path)
            print(f">>> Transcribed {len(transcribed_content)} characters in single pass.")

        # 3. Assemble Context
        sections = []
        combined_text = "\n\n".join(raw_text_parts).strip()
        if combined_text:
            sections.append(f"=== SLIDE & PRESENTATION CONTENT ===\n{combined_text}")
        if transcribed_content:
            sections.append(f"=== SPOKEN AUDIO TRANSCRIPTION ===\n{transcribed_content}")

        context_text = "\n\n".join(sections).strip()
        if not context_text:
            raise HTTPException(status_code=400, detail="No readable content found.")

        # Keep context under TPM limit
        if len(context_text) > 14000:
            context_text = context_text[:14000]

        system_instruction = (
            "You are an expert academic tutor and exam creator.\n"
            "You MUST respond ONLY with a single valid JSON object matching this schema:\n"
            "{\n"
            '  "title": "string",\n'
            '  "notes": "string (concise markdown study guide, max 200 words)",\n'
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
            "MATH RULES:\n"
            "1. Output valid JSON only (no markdown backticks ```json).\n"
            "2. Express math in plain text (e.g. '2^2', 'x_1', '(a+b)/c'). Do NOT use LaTeX backslashes.\n"
            f"3. Generate EXACTLY {num_questions} questions covering the material."
        )

        user_content = f"""
REQUIRED QUESTIONS: {num_questions}
DIFFICULTY: {difficulty}
CUSTOM INSTRUCTIONS: {custom_prompt or "Generate high-yield questions."}

SOURCE MATERIAL:
---
{context_text}
---
"""

        print(f">>> Prompting {TARGET_LLM_MODEL}...")
        completion = client.chat.completions.create(
            model=TARGET_LLM_MODEL,
            messages=[
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": user_content},
            ],
            response_format={"type": "json_object"},
            temperature=0.1,
            max_tokens=2000,
        )

        raw_output = completion.choices[0].message.content.strip()
        if raw_output.startswith("```json"):
            raw_output = raw_output[7:]
        if raw_output.startswith("```"):
            raw_output = raw_output[3:]
        if raw_output.endswith("```"):
            raw_output = raw_output[:-3]

        parsed = json.loads(raw_output.strip())
        print(f">>> Completed! Generated {len(parsed.get('quiz', []))} questions.")
        return parsed

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if temp_audio_path and os.path.exists(temp_audio_path):
            try:
                os.remove(temp_audio_path)
            except Exception:
                pass