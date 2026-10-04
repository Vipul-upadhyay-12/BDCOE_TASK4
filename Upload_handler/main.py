from fastapi import FastAPI, File, UploadFile, HTTPException
from groq import Groq
import cv2
import pytesseract
import shutil
import os
import json
import time
import subprocess

app = FastAPI()
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def extract_slide_text_fast(video_path, num_frames=3):
    """Extracts frames, downscales them to speed up OCR, and reads text with Tesseract."""
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if total_frames == 0:
        cap.release()
        return ""
        
    step = max(total_frames // (num_frames + 1), 1)
    slide_texts = []
    
    for count in range(1, num_frames + 1):
        frame_idx = count * step
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
        ret, frame = cap.read()
        if ret:
            # 1. Downscale frame to 720p width max to drastically reduce OCR time
            h, w = frame.shape[:2]
            scale = 720 / max(w, 720)
            resized = cv2.resize(frame, (int(w * scale), int(h * scale)))
            
            # 2. Grayscale + quick threshold for clean text
            gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
            
            # 3. PSM 6 tells Tesseract to assume a single uniform block of text (faster)
            text = pytesseract.image_to_string(gray, config='--psm 6')
            if text.strip():
                slide_texts.append(text.strip())
                
    cap.release()
    return "\n---\n".join(slide_texts)

@app.post("/upload-video")
async def upload_video(file: UploadFile = File(...)):
    start_time = time.time()
    
    video_path = f"temp_{file.filename}"
    audio_path = "temp_audio.mp3"
    
    try:
        # 1. Save incoming video
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 2. Direct, native FFmpeg extraction (10x faster than MoviePy, takes ~1-2s)
        cmd = [
            "ffmpeg", "-y", "-i", video_path, 
            "-vn", "-acodec", "libmp3lame", "-b:a", "64k", audio_path
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        
        # 3. Transcribe audio via Groq Whisper (<3s)
        with open(audio_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(audio_path, audio_file.read()),
                model="whisper-large-v3",
                response_format="json",
            )
        audio_text = transcription.text
        
        # 4. Fast Slide OCR (<10s)
        slide_text = extract_slide_text_fast(video_path)
        
        # 5. Merge and generate JSON via Groq (<3s)
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
        
        # Cleanup
        if os.path.exists(video_path): os.remove(video_path)
        if os.path.exists(audio_path): os.remove(audio_path)
        
        result_data["processing_time_seconds"] = round(time.time() - start_time, 2)
        return result_data
        
    except Exception as e:
        if os.path.exists(video_path): os.remove(video_path)
        if os.path.exists(audio_path): os.remove(audio_path)
        raise HTTPException(status_code=500, detail=str(e))