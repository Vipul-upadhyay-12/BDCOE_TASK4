from fastapi import FastAPI, File, UploadFile, HTTPException
from groq import Groq
from moviepy import VideoFileClip
import cv2
import pytesseract
import shutil
import os
import json
import time

app = FastAPI()
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def extract_slide_text(video_path, num_frames=3):
    """Extracts a few frames from the video and uses lightweight Tesseract OCR to read them."""
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if total_frames == 0:
        return ""
        
    step = max(total_frames // num_frames, 1)
    slide_text = ""
    
    for i in range(0, total_frames, step):
        cap.set(cv2.CAP_PROP_POS_FRAMES, i)
        ret, frame = cap.read()
        if ret:
            # Convert to grayscale for better OCR accuracy
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            text = pytesseract.image_to_string(gray)
            slide_text += f"\nSlide {i}:\n{text}"
            
        if len(slide_text.split("Slide")) > num_frames:
            break
            
    cap.release()
    return slide_text.strip()

@app.post("/upload-video")
async def upload_video(file: UploadFile = File(...)):
    start_time = time.time()
    
    video_path = f"temp_{file.filename}"
    audio_path = "temp_audio.mp3"
    
    try:
        # 1. Save Video
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 2. Extract Audio
        video = VideoFileClip(video_path)
        video.audio.write_audiofile(audio_path, logger=None)
        video.close()
        
        # 3. Read Audio (Whisper)
        with open(audio_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(audio_path, audio_file.read()),
                model="whisper-large-v3",
                response_format="json",
            )
        audio_text = transcription.text
        
        # 4. Read Slides (OpenCV + Tesseract)
        slide_text = extract_slide_text(video_path)
        
        # 5. Merge and Generate JSON (Groq Llama/GPT-OSS)
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
        
        # Clean up
        os.remove(video_path)
        os.remove(audio_path)
        
        # Record time
        result_data["processing_time_seconds"] = round(time.time() - start_time, 2)
        
        return result_data
        
    except Exception as e:
        if os.path.exists(video_path): os.remove(video_path)
        if os.path.exists(audio_path): os.remove(audio_path)
        raise HTTPException(status_code=500, detail=str(e))