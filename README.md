# EchoVoice

EchoVoice is a lightweight command-line tool that converts text into speech. It lets you pipe output from commands or provide text directly and hear it spoken aloud, making logs, notifications, and CLI workflows more accessible and interactive.

## Installation

Ensure you have Python 3 installed. You also need to install `espeak-ng`:

```bash
sudo apt update
sudo apt install espeak-ng
```

## Usage

### Basic Usage
Convert a string to speech:
```bash
python3 main.py "Hola, com estàs?"
```

### Natural Speech (Online)
Use the more natural Google engine (requires internet):
```bash
python3 main.py "Bon dia a tothom" -e google
```

### Voice/Language Selection
Specify a language code (e.g., 'ca' for Catalan, 'en' for English):
```bash
python3 main.py "Hello everyone" -e google -v en
```

### Piped Input
Pipe the output of any command to EchoVoice:
```bash
echo "Process finished successfully" | python3 main.py
```

## Options

- `-e, --engine`: Choose between `google` (natural, online) or `espeak-ng` (robotic, offline). Default is `google`.
- `-v, --voice`: Language/voice code (e.g., `ca`, `en`, `es`, `fr`). Default is `ca`.
- `-o, --output`: Save speech to an audio file (wav for espeak, mp3 for google).
- `-r, --rate`: Speech rate (words per minute, for `espeak-ng`).
- `-p, --pitch`: Pitch (0-99, for `espeak-ng`).
- `--no-cache`: Disable audio caching.

## Features

- **Natural Speech**: Uses Google Translate TTS by default for high-quality audio.
- **Offline Fallback**: Automatically switches to `espeak-ng` if internet is unavailable.
- **Language Detection**: Automatically identifies the language of the input text.
- **Audio Caching**: Stores generated audio files in `~/.cache/echovoice/` to avoid repeated API calls and improve performance.

### Example
```bash
python3 main.py "Hola, aquesta frase es quedarà a la caché."
# Second time will be instant:
python3 main.py "Hola, aquesta frase es quedarà a la caché."
```

