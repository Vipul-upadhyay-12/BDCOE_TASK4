from fastapi import FastAPI, File, UploadFile, HTTPException
from groq import Groq
import requests
import shutil
import os
import json
import time
import subprocess

app = FastAPI()
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def get_ocr_text(image_path):
    """Sends the extracted frame to a free, dedicated OCR API to avoid crashing Render's CPU."""
    try:
        with open(image_path, 'rb') as f:
            response = requests.post(
                'https://api.ocr.space/parse/image',
                files={image_path: f},
                data={'apikey': 'helloworld', 'language': 'eng'}
            )
        result = response.json()
        if not result.get("IsErroredOnProcessing") and result.get("ParsedResults"):
            return result["ParsedResults"][0]["ParsedText"]
    except Exception:
        pass
    return ""

@app.post("/upload-video")
async def upload_video(file: UploadFile = File(...)):
    start_time = time.time()
    
    video_path = f"temp_{file.filename}"
    audio_path = "temp_audio.mp3"
    image_path = "temp_frame.jpg"
    
    try:
        # 1. Save Video
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 2. Extract Audio (Native FFmpeg = ~1 second)
        subprocess.run([
            "ffmpeg", "-y", "-i", video_path, 
            "-vn", "-acodec", "libmp3lame", "-b:a", "64k", audio_path
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        
        # 3. Extract 1 Key Slide (Native FFmpeg = ~0.2 seconds)
        # Grabs a frame 3 seconds into the video to avoid black starting screens
        subprocess.run([
            "ffmpeg", "-y", "-ss", "00:00:03", "-i", video_path, 
            "-frames:v", "1", "-q:v", "2", image_path
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        
        # 4. Transcribe Audio (Groq API = ~2 seconds)
        with open(audio_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(audio_path, audio_file.read()),
                model="whisper-large-v3",
                response_format="json",
            )
        audio_text = transcription.text
        
        # 5. Extract Text from Slide (OCR.space API = ~2 seconds)
        slide_text = get_ocr_text(image_path)
        
        # 6. Merge & Format (Groq LLM = ~2 seconds)
        prompt = f"""
        Based on the spoken transcript and the text found on the video slides, generate concise study notes and a short multiple-choice quiz (3-5 questions).
        You must return ONLY a JSON object with exactly two keys:
        1. "notes": A string containing Markdown-formatted study notes.
        2. "quiz": A list of question objects, each with 'question' (string), 'options' (list of strings), and 'answer' (string).
        
        Spoken Transcript: {audio_text}
        Slide Text: {slide_text}
        """
        
        completion = client.chat.completions.create(
            model="openai/gpt-oss-20b",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.3,
            max_tokens=4096,
        )
        
        result_data = json.loads(completion.choices[0].message.content)
        
        # Cleanup files
        for p in [video_path, audio_path, image_path]:
            if os.path.exists(p): os.remove(p)
            
        result_data["processing_time_seconds"] = round(time.time() - start_time, 2)
        return result_data
        
    except Exception as e:
        for p in [video_path, audio_path, image_path]:
            if os.path.exists(p): os.remove(p)
        raise HTTPException(status_code=500, detail=str(e))