from flask import Flask, request, jsonify, send_from_directory, send_file
import subprocess
import os
import requests
import io
import re

app = Flask(__name__)

# Directory to store downloaded, converted files, and thumbnails
DOWNLOAD_FOLDER = 'assets/musiche'
CONVERTED_FOLDER = 'assets/musiche'
THUMBNAIL_FOLDER = 'assets/copertine'

# Create directories if they don't exist
os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)
os.makedirs(CONVERTED_FOLDER, exist_ok=True)
os.makedirs(THUMBNAIL_FOLDER, exist_ok=True)

@app.route('/search', methods=['GET'])
def search_video():
    """Search for videos on YouTube based on the title or artist."""
    query = request.args.get('query')  # Song title or artist
    if not query:
        return jsonify({"error": "Query is required"}), 400

    video_info = search_video_yt_dlp(query)
    if not video_info:
        return jsonify({"error": "Failed to find videos"}), 500

    return jsonify({"status": "success", "video_info": video_info})

def search_video_yt_dlp(query):
    """Search YouTube using yt-dlp and return a list of video details including thumbnails."""
    try:
        result = subprocess.run(
            ['yt-dlp', f'ytsearch10:{query}', '--get-title', '--get-id', '--get-thumbnail', '--no-check-certificate'],
            capture_output=True, text=True, check=True
        )
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 3:
            video_info = []
            for i in range(0, len(lines), 3):
                title = lines[i]
                video_id = lines[i+1]
                thumbnail = lines[i+2]
                video_url = f'https://www.youtube.com/watch?v={video_id}'
                video_info.append({'title': title, 'url': video_url, 'thumbnail': thumbnail})

            return video_info
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error during search: {e}")
        return None

@app.route('/download-and-convert', methods=['POST'])
def download_and_convert():
    """Download a YouTube video, convert it to MP3, and save the thumbnail."""
    url = request.json.get('url')
    if not url:
        return jsonify({"error": "URL is required"}), 400

    video_filename, title, thumbnail_url = download_video(url)
    if not video_filename:
        return jsonify({"error": "Failed to download video"}), 500

    # Save the thumbnail after downloading
    save_thumbnail(thumbnail_url, title)

    # Since download_video already converts the audio to MP3, no need for additional conversion
    mp3_url = f'http://127.0.0.1:5000/converted/{os.path.basename(video_filename)}'
    return jsonify({"status": "success", "mp3_url": mp3_url})


def download_video(url):
    """Download a video from YouTube using yt-dlp (download only audio)."""
    try:
        result = subprocess.run(
            ['yt-dlp', '-f', 'bestaudio', '--extract-audio', '--audio-format', 'mp3', '--audio-quality', '0', '--get-title', '--get-thumbnail', url],
            capture_output=True, text=True, check=True
        )
        lines = result.stdout.strip().split('\n')
        if len(lines) < 2:
            return None, None, None
        
        title = lines[0].replace('/', '_')  # Ensure no invalid characters in filename
        thumbnail_url = lines[1]

        video_filename = f"{title}.mp3"  # Ensure the file extension is mp3
        output_path = os.path.join(DOWNLOAD_FOLDER, video_filename)

        # Download only the audio in mp3 format
        command = ['yt-dlp', '-f', 'bestaudio', '--extract-audio', '--audio-format', 'mp3', '--audio-quality', '0', '-o', output_path, url]
        print(f"Running command: {' '.join(command)}")
        subprocess.run(command, check=True)

        # Return the downloaded file and other metadata
        return os.path.join(DOWNLOAD_FOLDER, video_filename), title, thumbnail_url
    except Exception as e:
        print(f"Error downloading video: {e}")
        return None, None, None

import re

def save_thumbnail(thumbnail_url, title):
    """Download and save the thumbnail image."""
    try:
        # Rimuovi o sostituisci i caratteri non validi nei nomi dei file
        # Sostituisci i caratteri non validi con un underscore "_"
        valid_title = re.sub(r'[<>:"/\\|?*]', '_', title)

        # Assicurati che il nome del file sia sicuro per il sistema operativo
        thumbnail_path = os.path.join(THUMBNAIL_FOLDER, f"{valid_title}.jpg")
        
        response = requests.get(thumbnail_url, stream=True)
        if response.status_code == 200:
            with open(thumbnail_path, 'wb') as f:
                for chunk in response.iter_content(1024):
                    f.write(chunk)
            print(f"Thumbnail saved to {thumbnail_path}")
        else:
            print(f"Failed to fetch thumbnail: {thumbnail_url}")
    except Exception as e:
        print(f"Error saving thumbnail: {e}")



def convert_to_mp3(video_path):
    """Convert a video file (webm) to MP3 using FFmpeg."""
    try:
        # Verifica se il file esiste
        if not os.path.exists(video_path):
            print(f"File non trovato: {video_path}")
            return None

        # Crea la cartella di destinazione se non esiste
        if not os.path.exists(CONVERTED_FOLDER):
            os.makedirs(CONVERTED_FOLDER)

        # Estrai il nome del file e imposta il nome del file MP3 di destinazione
        base_name = os.path.splitext(os.path.basename(video_path))[0]
        mp3_filename = f"{base_name}.mp3"
        output_path = os.path.join(CONVERTED_FOLDER, mp3_filename)

        # Comando FFmpeg per estrarre l'audio dal file .webm e convertirlo in MP3
        command = [
            'ffmpeg', '-i', video_path, '-vn', '-acodec', 'libmp3lame', '-q:a', '2', '-map', 'a', output_path
        ]

        print(f"Esecuzione comando: {' '.join(command)}")

        # Esegui il comando
        result = subprocess.run(command, capture_output=True, text=True)

        # Log dei dettagli di esecuzione
        print(f"FFmpeg stdout: {result.stdout}")
        print(f"FFmpeg stderr: {result.stderr}")

        # Controlla se il comando è stato eseguito con successo
        if result.returncode != 0:
            print(f"Errore durante la conversione: {result.stderr}")
            return None

        # Elimina il file originale se la conversione ha avuto successo
        os.remove(video_path)
        print(f"File MP3 salvato come: {output_path}")
        return output_path

    except FileNotFoundError as e:
        print(f"Errore: Il file {video_path} non è stato trovato. Dettagli: {e}")
        return None
    except PermissionError as e:
        print(f"Errore di permessi: {e}")
        return None
    except Exception as e:
        print(f"Errore durante la conversione in MP3: {e}")
        return None

@app.route('/modify-pitch', methods=['POST'])
def modify_pitch():
    """Modify the pitch of the uploaded MP3 file and save it with a new name."""
    file = request.files.get('file')  # Get the uploaded file
    pitch = request.form.get('pitch', type=float)  # Get the pitch factor from the request

    if not file or pitch is None:
        return {"error": "File and pitch factor are required"}, 400

    try:
        # Create a temporary file to save the modified MP3 with the new name
        title = file.filename.rsplit('.', 1)[0]  # Get the title (file name without extension)
        output_filename = f"{title} (Speed Up).mp3"  # New filename with the pitch change tag
        output_path = os.path.join(CONVERTED_FOLDER, output_filename)

        # Use ffmpeg to adjust the pitch and save it directly to the output file
        command = [
            'ffmpeg', '-i', 'pipe:0', '-filter:a', f'asetrate=44100*{pitch},aresample=44100', '-f', 'mp3', output_path
        ]
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stderr=subprocess.PIPE)

        # Read the file content and pass it to ffmpeg via stdin
        stdout, stderr = process.communicate(input=file.read())

        if process.returncode != 0:
            raise Exception(f"Error during pitch modification: {stderr.decode('utf-8')}")

        # Return the file URL after saving
        mp3_url = f'http://127.0.0.1:5000/converted/{output_filename}'
        return jsonify({"status": "success", "mp3_url": mp3_url})

    except Exception as e:
        return {"error": str(e)}, 500


@app.route('/converted/<filename>', methods=['GET'])
def serve_converted(filename):
    """Serve the converted MP3 file."""
    return send_from_directory(CONVERTED_FOLDER, filename)

@app.route('/thumbnails/<filename>', methods=['GET'])
def serve_thumbnail(filename):
    """Serve the downloaded thumbnail."""
    return send_from_directory(THUMBNAIL_FOLDER, filename)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080, debug=False)