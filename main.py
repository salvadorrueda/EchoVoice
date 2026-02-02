#!/usr/bin/env python3
import sys
import argparse
import subprocess
import shutil
import os
import tempfile
import requests
import hashlib

def get_cache_dir():
    """Returns the cache directory path."""
    cache_dir = os.path.expanduser("~/.cache/echovoice")
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir, exist_ok=True)
    return cache_dir

def get_cache_path(text, engine, lang, rate=175, pitch=50):
    """Generates a unique cache path for the given parameters."""
    # Create a unique key based on inputs
    key_str = f"{text}|{engine}|{lang}|{rate}|{pitch}"
    key_hash = hashlib.sha256(key_str.encode()).hexdigest()
    
    extension = ".mp3" if engine == "google" else ".wav"
    return os.path.join(get_cache_dir(), f"{key_hash}{extension}")

def detect_language(text):
    """Detects the language of the text using a lightweight Google API."""
    if not text or len(text.strip()) < 3:
        return "ca" # Default to Catalan for very short text
    
    url = "https://translate.googleapis.com/translate_a/single"
    params = {
        "client": "gtx",
        "sl": "auto",
        "tl": "en", # Target language doesn't matter for detection
        "dt": "t",
        "q": text
    }
    
    try:
        response = requests.get(url, params=params, timeout=5)
        response.raise_for_status()
        # The response is a nested list, the detected language is at index 2
        data = response.json()
        if len(data) > 2 and isinstance(data[2], str):
            detected = data[2]
            print(f"Detected language: {detected}")
            return detected
    except Exception as e:
        print(f"Warning: Language detection failed ({e}). Defaulting to 'ca'.", file=sys.stderr)
    
    return "ca"

def play_audio(file_path):
    """Helper to play audio using available system tools."""
    if shutil.which("gst-launch-1.0"):
        cmd = [
            "gst-launch-1.0", "-q", 
            "filesrc", f"location={file_path}", "!", 
            "decodebin", "!", "audioconvert", "!", 
            "audioresample", "!", "autoaudiosink"
        ]
    elif shutil.which("mpv"):
        cmd = ["mpv", "--no-terminal", file_path]
    elif shutil.which("ffplay"):
        cmd = ["ffplay", "-nodisp", "-autoexit", file_path]
    else:
        print("Error: No audio player found (gst-launch-1.0, mpv, or ffplay).", file=sys.stderr)
        print(f"Audio saved to: {file_path}", file=sys.stderr)
        return False
    
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def run_tts(text, engine="google", voice=None, output_file=None, rate=175, pitch=50, use_cache=True):
    """Runs the selected TTS engine."""
    # Detect language if not specified
    lang = voice if voice else detect_language(text)
    
    # Cache management
    cache_path = None
    if use_cache and not output_file:
        cache_path = get_cache_path(text, engine, lang, rate, pitch)
        if os.path.exists(cache_path):
            print(f"Using cached audio: {cache_path}")
            play_audio(cache_path)
            return

    if engine == "google":
        # Google Translate TTS (online)
        url = "https://translate.google.com/translate_tts"
        params = {
            "ie": "UTF-8",
            "q": text,
            "tl": lang,
            "client": "tw-ob"
        }
        
        try:
            print(f"Requesting natural speech from Google (lang: {lang})...")
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            if output_file:
                with open(output_file, 'wb') as f:
                    f.write(response.content)
                print(f"Generated audio file: {output_file}")
            else:
                # Save to cache if enabled
                save_path = cache_path if use_cache else None
                if not save_path:
                    # If cache disabled or failed, use a temp file
                    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tf:
                        tf.write(response.content)
                        save_path = tf.name
                else:
                    with open(save_path, 'wb') as f:
                        f.write(response.content)
                
                try:
                    play_audio(save_path)
                finally:
                    # Only delete if it's NOT a cache file
                    if not use_cache and os.path.exists(save_path):
                        os.remove(save_path)
                        
        except Exception as e:
            print(f"Error using Google TTS: {e}", file=sys.stderr)
            print("Falling back to espeak-ng...", file=sys.stderr)
            run_tts(text, engine="espeak-ng", voice=lang, output_file=output_file, rate=rate, pitch=pitch, use_cache=use_cache)

    elif engine == "espeak-ng":
        if not shutil.which("espeak-ng"):
            print("Error: espeak-ng is not installed. Please install it using: sudo apt install espeak-ng", file=sys.stderr)
            sys.exit(1)
        
        # Determine actual file to write to
        internal_output = output_file
        if not internal_output and use_cache:
            internal_output = cache_path

        # Build command
        # -v: voice/language
        # -s: speed (words per minute)
        # -p: pitch (0-99)
        cmd = ["espeak-ng", "-s", str(rate), "-p", str(pitch)]
        cmd += ["-v", lang]
            
        if internal_output:
            cmd += ["-w", internal_output]
            if output_file:
                print(f"Generating audio file: {output_file}...")
        
        try:
            # If no output file and no cache, espeak plays directly.
            # Otherwise, we write to file and then play.
            subprocess.run(cmd, input=text, text=True, check=True)
            
            if internal_output and not output_file:
                play_audio(internal_output)
                
        except subprocess.CalledProcessError as e:
            print(f"Error running espeak-ng: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"Error: Engine '{engine}' not implemented yet.", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="EchoVoice: A lightweight command-line tool that converts text into speech.",
        epilog="Example: echo 'Hola món' | echovoice -e google -v ca"
    )
    parser.add_argument(
        "text", 
        nargs="?", 
        help="Text to speak. If omitted, reads from stdin."
    )
    parser.add_argument(
        "-e", "--engine", 
        default="google", 
        choices=["espeak-ng", "google"],
        help="TTS engine (default: google)"
    )
    parser.add_argument(
        "-v", "--voice",
        help="Voice/Language code (e.g., 'ca' for Catalan, 'en' for English)"
    )
    parser.add_argument(
        "-o", "--output", 
        help="Save speech to an audio file instead of playing it."
    )
    parser.add_argument(
        "-r", "--rate", 
        type=int, 
        default=175, 
        help="Speech rate (words per minute, default: 175)"
    )
    parser.add_argument(
        "-p", "--pitch", 
        type=int, 
        default=50, 
        help="Pitch (0-99, for espeak-ng, default: 50)"
    )
    parser.add_argument(
        "--no-cache",
        action="store_false",
        dest="use_cache",
        help="Disable audio caching."
    )

    args = parser.parse_args()

    # Handle input: argument or stdin
    if args.text:
        text_to_speak = args.text
    else:
        if sys.stdin.isatty():
            parser.print_help()
            sys.exit(0)
        text_to_speak = sys.stdin.read().strip()

    if not text_to_speak:
        print("Warning: No text provided.", file=sys.stderr)
        return

    run_tts(
        text_to_speak, 
        engine=args.engine, 
        voice=args.voice,
        output_file=args.output, 
        rate=args.rate, 
        pitch=args.pitch,
        use_cache=args.use_cache
    )

if __name__ == "__main__":
    main()
