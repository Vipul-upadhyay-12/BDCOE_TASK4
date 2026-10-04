from fastapi import FastAPI, File, UploadFile, HTTPException
from groq import Groq
from moviepy.editor import VideoFileClip
import shutil
import os
import json

app = FastAPI()

# Initialize the Groq client
# It automatically looks for an environment variable named GROQ_API_KEY
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

@app.post("/upload-video")
async def upload_video(file: UploadFile = File(...)):
    video_path = f"temp_{file.filename}"
    audio_path = "temp_audio.mp3"
    
    try:
        # 1. Save the incoming video temporarily
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 2. Extract the audio using MoviePy
        video = VideoFileClip(video_path)
        video.audio.write_audiofile(audio_path, logger=None)
        video.close()
        
        # 3. Transcribe the audio using Groq (Whisper-large-v3)
        with open(audio_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(audio_path, audio_file.read()),
                model="whisper-large-v3",
                response_format="json",
            )
        transcript_text = transcription.text
        
        # 4. Generate the Quiz and Notes using Groq (Llama 3)
        # We enforce JSON output so your frontend can easily parse it
        prompt = f"""
        Based on the following transcript, generate study notes and a multiple-choice quiz.
        You must return ONLY a JSON object with exactly two keys:
        1. "notes": A string containing Markdown-formatted study notes.
        2. "quiz": A list of question objects, each with 'question' (string), 'options' (list of strings), and 'answer' (string).
        
        Transcript: {transcript_text}
        """
        
        completion = client.chat.completions.create(
            model="llama3-8b-8192",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.3,
        )
        
        # Parse the JSON string from Groq into a Python dictionary
        result_data = json.loads(completion.choices[0].message.content)
        
        # 5. Clean up the temporary files so the server doesn't run out of storage
        os.remove(video_path)
        os.remove(audio_path)
        
        # Return the final JSON to the user!
        return result_data
        
    except Exception as e:
        # If anything goes wrong, clean up the files and show the error
        if os.path.exists(video_path): os.remove(video_path)
        if os.path.exists(audio_path): os.remove(audio_path)
        raise HTTPException(status_code=500, detail=str(e))