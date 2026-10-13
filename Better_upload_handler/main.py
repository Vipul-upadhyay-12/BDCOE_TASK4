import os
import io
import time
import json
import shutil
import subprocess
from typing import Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from pypdf import PdfReader
from pptx import Presentation

app = FastAPI(title="ToolForge Universal Handler")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))


def extract_text_from_pptx(file_bytes: bytes) -> str:
    prs = Presentation(io.BytesIO(file_bytes))
    text_runs = []
    for i, slide in enumerate(prs.slides):
        slide_texts = []
        for shape in slide.shapes:
            if shape.has_text_frame:
                for paragraph in shape.text_frame.paragraphs:
                    line = paragraph.text.strip()
                    if line:
                        slide_texts.append(line)
        if slide_texts:
            text_runs.append(f"--- Slide {i + 1} ---\n" + "\n".join(slide_texts))
    return "\n\n".join(text_runs)


def extract_text_from_doc(file_bytes: bytes, filename: str) -> str:
    name = filename.lower()
    if name.endswith(".pdf"):
        reader = PdfReader(io.BytesIO(file_bytes))
        pages_text = [page.extract_text() or "" for page in reader.pages]
        return "\n".join(pages_text).strip()
    elif name.endswith(".pptx"):
        return extract_text_from_pptx(file_bytes)
    elif name.endswith(".txt"):
        return file_bytes.decode("utf-8", errors="ignore").strip()
    return ""


@app.post("/generate-quiz")
async def generate_quiz(
    file: UploadFile = File(...),
    num_questions: int = Form(5),
    difficulty: str = Form("Medium"),
    custom_prompt: Optional[str] = Form(None),
):
    start_time = time.time()
    filename = file.filename or "uploaded_file"
    ext = os.path.splitext(filename)[1].lower()

    # Unique temp file naming to prevent collisions
    timestamp_prefix = int(time.time())
    video_path = f"temp_{timestamp_prefix}_{filename}"
    audio_path = f"temp_{timestamp_prefix}.mp3"

    context_text = ""

    try:
        # 1. Documents (PDF, PPTX, TXT) -> Sub-second processing
        if ext in [".pdf", ".pptx", ".txt"]:
            file_bytes = await file.read()
            context_text = extract_text_from_doc(file_bytes, filename)

        # 2. Pure Audio (MP3, WAV, M4A) -> Direct Whisper transcription
        elif ext in [".mp3", ".wav", ".m4a", ".aac"]:
            content = await file.read()
            transcription = client.audio.transcriptions.create(
                file=(filename, content),
                model="whisper-large-v3",
                response_format="json",
            )
            context_text = transcription.text

        # 3. Video (MP4, MKV, MOV) -> Single-pass extraction
        elif ext in [".mp4", ".mkv", ".mov", ".avi", ".webm"]:
            with open(video_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            # Single-pass fast audio stripping: mono, 16kHz, low bitrate (under 5 seconds)
            ffmpeg_cmd = [
                "ffmpeg", "-y",
                "-i", video_path,
                "-vn",
                "-ac", "1",
                "-ar", "16000",
                "-b:a", "32k",
                audio_path
            ]
            subprocess.run(
                ffmpeg_cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True
            )

            with open(audio_path, "rb") as af:
                transcription = client.audio.transcriptions.create(
                    file=(audio_path, af.read()),
                    model="whisper-large-v3",
                    response_format="json",
                )
            context_text = transcription.text

        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported format '{ext}'. Supported: .pdf, .pptx, .txt, .mp3, .wav, .mp4, .mkv",
            )

        if not context_text or not context_text.strip():
            raise HTTPException(status_code=400, detail="No readable content or transcript found in file.")

        # Limit context window to the first 12,000 characters for instant LLM response
        context_preview = context_text[:12000]

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
{context_preview}
---
"""

        # Llama 3.1 8b is ultra-fast (~1-2 seconds on Groq LPUs)
        candidate_models = [
            "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile",
        ]

        completion = None
        last_error = None

        for model_name in candidate_models:
            try:
                completion = client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {"role": "system", "content": system_instruction},
                        {"role": "user", "content": user_content},
                    ],
                    response_format={"type": "json_object"},
                    temperature=0.2,
                    max_tokens=3000,
                )
                if completion:
                    break
            except Exception as err:
                last_error = err
                continue

        if not completion:
            raise HTTPException(
                status_code=500,
                detail=f"Groq generation failed across all models. Last error: {str(last_error)}",
            )

        result_data = json.loads(completion.choices[0].message.content)
        result_data["processing_time_seconds"] = round(time.time() - start_time, 2)
        return result_data

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        for p in [video_path, audio_path]:
            if os.path.exists(p):
                try:
                    os.remove(p)
                except Exception:
                    pass


@app.get("/")
def root():
    return {"status": "running", "service": "ToolForge Backend"}