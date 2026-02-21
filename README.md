# Qlarity

A Rails 8 application that transforms uploaded documents into accessible,
dyslexia-friendly text using Claude AI.

---

## Text Extraction

Qlarity can extract and reformat text from images, screenshots, and PDFs.

### How it works

| Input | Method |
|---|---|
| `.png` `.jpg` `.jpeg` `.webp` | Claude vision (direct) |
| `.pdf` with a text layer | `pdf-reader` gem (fast, offline) |
| Scanned / image-only PDF | Each page rendered to PNG → Claude vision |

Every extraction produces three outputs:

- **raw_text** – verbatim text as extracted
- **clean_text** – hyphenation fixed, whitespace normalised
- **readable_text** – dyslexia-friendly: short chunks, bullet lists, section separators

### Setup

1. **API keys** – set in your environment (or `.env` file):

   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ELEVENLABS_API_KEY=sk-...     # required only for speech generation
   ```

2. **System dependencies** (only needed for scanned PDFs):
   - [ImageMagick](https://imagemagick.org/) with Ghostscript support
   - On macOS: `brew install imagemagick ghostscript`
   - On Debian/Ubuntu: `apt-get install imagemagick ghostscript`

3. **Install gems**:

   ```
   bundle install
   ```

### CLI usage

```
bin/extract <file> [--speak] [--voice=NAME] [--speed=FLOAT]
```

Examples:

```bash
bin/extract invoice.pdf
bin/extract screenshot.png

# Generate speech with default voice and speed
bin/extract invoice.pdf --speak

# Choose voice and speed
bin/extract scan.jpg --speak --voice=aria --speed=0.7
```

Voices: `rachel` (default), `aria`, `roger`, `sarah`, `george`
Speed: `0.7` = slow, `1.0` = normal (default), `1.3` = fast

Output is printed to stdout and three files are saved to `tmp/extractions/`:

```
tmp/extractions/invoice_raw.txt
tmp/extractions/invoice_clean.txt
tmp/extractions/invoice_readable.txt
```

With `--speak`, the MP3 is saved to `public/audio/` and the playable URL is printed.

### Using the services in Ruby

```ruby
# Text extraction only
result = TextExtractor.call("path/to/file.pdf")

result.raw_text       # verbatim
result.clean_text     # normalised
result.readable_text  # dyslexia-friendly
result.method_used    # "pdf_text_layer" | "pdf_vision" | "image_vision"
result.per_page       # [{page: 1, text: "..."}, ...] or nil for images
result.speech_enabled # false
result.audio_url      # nil

# Extraction + speech in one call
result = TextExtractor.call("path/to/file.pdf", speech_enabled: true, voice: "rachel", speed: 1.0)
result.audio_url      # "/audio/abc123.mp3"

# Generate speech from any text
tts = TTSService.speak("Hello world", voice: "aria", speed: 1.0)
tts.audio_url         # "/audio/abc123.mp3"

# Available voices
TTSService::VOICES.keys  # ["rachel", "aria", "roger", "sarah", "george"]

# Reformat any text independently:
DyslexiaFormatter.format(some_text)

# Clean text independently:
TextCleaner.clean(some_text)
```

---

## Text-to-Speech (ElevenLabs)

After picking a transformation on the collapsed view, click **Generate Speech** to convert it to audio. Controls:

- **Voice** – choose from Rachel, Aria, Roger, Sarah, or George
- **Speed** – Slow (0.7×), Normal (1.0×), or Fast (1.3×) — adjusted client-side via the audio element's `playbackRate`

Audio files are saved to `public/audio/` and served statically.

---

## Running tests

```
bundle exec rspec
```

## Starting the development server

```
bin/dev
```
