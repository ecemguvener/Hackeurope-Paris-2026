# Qlarity — AI-Powered Dyslexia-Friendly Reader

**Live app:** [https://qlarity.onrender.com](https://qlarity.onrender.com)

Qlarity transforms dense corporate text into accessible, readable content using AI semantic rewriting, personalized user profiles, and natural text-to-speech. Built for the 15% of the workforce with dyslexia who struggle daily with Slack messages, Jira tickets, emails, and PDFs.

## The Problem

Existing accessibility tools like Helperbird, OpenDyslexic, and BeeLine Reader only apply surface-level CSS changes — different fonts, colors, and spacing — identically for every user. None of them actually **rewrite text** to improve comprehension. Meanwhile:

- Dense corporate text with long sentences, jargon, and visual crowding remains unreadable
- One-size-fits-all styling ignores that dyslexia manifests differently for each person
- Organizations have no way to measure the ROI of accessibility investments
- "Dyslexia tool" branding creates stigma and discourages adoption

## The Solution

Qlarity uses Claude's language understanding to **semantically transform text** while preserving meaning — not just restyle it. A personalized reading profile adapts transformations to each user's specific needs, and natural text-to-speech provides a second channel for comprehension.

### Key Innovation: The Superposition Model

The same user profile produces different transformations depending on content type. A short Slack message gets minimal changes. A dense technical document gets maximum restructuring. One profile, context-aware output.

## How It Works

**Upload or select text** &rarr; **AI extracts and transforms** &rarr; **Read or listen in your preferred style**

1. Users complete a quick reading assessment (no medical language) that builds a personalized accessibility profile
2. Text is extracted from documents (PDF, images) using Claude's vision capabilities or selected directly from web pages via the Chrome extension
3. Claude generates four transformation styles simultaneously in a single API call:
   - **Simplified** — shorter sentences, clearer structure
   - **Bullet Points** — scannable key information
   - **Plain Language** — jargon replaced with everyday words
   - **Restructured** — better reading flow and organization
4. The system autonomously recommends the best style based on the user's profile and content type
5. Users can listen to transformed text with natural voices via ElevenLabs

## Technology Stack

### Claude (Anthropic)

Claude powers every AI capability in Qlarity:

- **Vision-based text extraction** — Extracts text from images and scanned PDFs using `claude-sonnet-4-6`, producing raw, clean, and dyslexia-formatted output
- **Semantic text transformation** — Rewrites text into four accessible styles using personalized system prompts built from each user's reading profile
- **Bulk superposition generation** — A single Claude API call returns all four transformation styles as structured JSON, along with an autonomous style recommendation
- **Conversational Q&A** — Users can chat with page content through the Chrome extension, with Claude maintaining conversation history and page context
- **Summarization** — Generates 3-5 bullet point summaries from any text

### Paid.ai

Paid.ai handles usage-based billing and quota management for enterprise deployment:

- **Quota checking** — Verifies remaining credits before text extraction and TTS generation
- **Usage recording** — Tracks every action (extractions, speech generations) with metadata like page count, character count, voice selection, and estimated audio minutes
- **Credit bundles** — Fetches and calculates remaining credits from customer accounts
- **Billing dashboard** — Displays plan details, usage summary, and remaining credits
- **Fail-open design** — If the billing API is unreachable, requests proceed rather than blocking users

### LangSmith

LangSmith provides the observability layer for proving accessibility ROI:

- **Transformation tracing** — Every Claude call is tagged with `user_id`, `content_type`, `cost`, `latency`, and `readability_delta`
- **Readability metrics** — Tracks Flesch-Kincaid grade level improvements (e.g., grade 12.3 reduced to 9.8)
- **Value measurement** — Quantifies the impact of AI transformations for enterprise stakeholders
- **Non-blocking** — Tracing failures never interrupt the user-facing pipeline

### ElevenLabs

ElevenLabs provides natural text-to-speech for dual-channel accessibility:

- **Five voice options** — Rachel, Aria, Roger, Sarah, and George
- **Speed control** — Slow (0.7x), Normal (1.0x), and Fast (1.2x) via the `eleven_turbo_v2_5` model
- **Smart chunking** — Long text is automatically split at sentence boundaries (max 2,500 characters per chunk) and concatenated into a single MP3
- **Retry logic** — Handles API timeouts gracefully with automatic retries

### Ruby on Rails

Rails 8.1 provides the full-stack foundation:

- **Service objects** — Clean separation of concerns with dedicated services for extraction, transformation, TTS, chat, billing, and summarization
- **PostgreSQL** — Stores users, documents, interactions, and transformation results
- **Hotwire (Turbo + Stimulus)** — Real-time UI updates without heavy JavaScript frameworks
- **Tailwind CSS** — Accessible, responsive styling via Propshaft asset pipeline
- **Solid Queue / Solid Cache / Solid Cable** — Database-backed background jobs, caching, and WebSocket support
- **RESTful API** — JSON endpoints for the Chrome extension (`/api/v1/transform`, `/api/v1/tts`, `/api/v1/chat`)

### Chrome Extension

A Manifest V3 Chrome extension brings Qlarity to any web page:

- **Floating action button** — A small "Q" button on every page that detects text selection
- **Side panel UI** — Three tabs: Transform, Chat, and Listen
- **Page text extraction** — Intelligently extracts main content from semantic HTML elements, filtering out navigation, ads, and scripts
- **Real-time transformation** — Select text on any page, choose a style, and read the accessible version instantly
- **Chat with context** — Ask questions about page content with full conversation history
- **Text-to-speech player** — Generate and play audio with voice and speed controls
- **Reading overlay** — Optional tinted screen filter for color-sensitive readers
- **Fullscreen reader** — Distraction-free reading mode for transformed content

## Architecture

```
Chrome Extension                 Rails API                    External Services
+-----------------+     +------------------------+     +-------------------+
| Content Script  |---->| /api/v1/transform      |---->| Claude (Anthropic)|
| Side Panel      |---->| /api/v1/tts            |---->| ElevenLabs        |
| Background SW   |---->| /api/v1/chat           |---->| Paid.ai           |
+-----------------+     | /api/v1/interactions   |---->| LangSmith         |
                        +------------------------+     +-------------------+
Web UI                          |
+-----------------+     +-------v--------+
| Document Upload |---->| Service Objects|
| Reading Profile |     | - TextExtractor|
| Billing Dashboard|    | - TransformSvc |
| Optimized View  |     | - TTSService   |
+-----------------+     | - BillingService|
                        | - ChatService  |
                        +----------------+
```

## Getting Started

### Prerequisites

- **Ruby 3.4.8** — install via [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/)
- **PostgreSQL** — install via `brew install postgresql` (macOS) or `apt install postgresql` (Ubuntu)
- **Node.js** (optional, for asset pipeline)
- **ImageMagick + Ghostscript** (only needed for scanned PDF extraction):
  ```bash
  # macOS
  brew install imagemagick ghostscript

  # Ubuntu/Debian
  sudo apt install imagemagick ghostscript
  ```

### Step 1: Clone the repo

```bash
git clone https://github.com/ecemguvener/Hackeurope-Paris-2026.git
cd Hackeurope-Paris-2026
```

### Step 2: Install Ruby dependencies

```bash
bundle install
```

### Step 3: Configure environment variables

```bash
cp .env.example .env
```

Open `.env` and add your API keys:

```
ANTHROPIC_API_KEY=sk-ant-...        # Required — get from https://console.anthropic.com
ELEVENLABS_API_KEY=sk-...           # Optional — get from https://elevenlabs.io
PAID_API_KEY=...                    # Optional — get from https://app.paid.ai
```

Without `ELEVENLABS_API_KEY`, TTS falls back to browser Speech Synthesis.
Without `PAID_API_KEY`, billing runs in stub mode (all requests allowed, usage logged only).

### Step 4: Set up the database

```bash
bin/rails db:create db:migrate db:seed
```

### Step 5: Start the development server

```bash
bin/dev
```

This starts both the Rails server and Tailwind CSS watcher. The app will be available at **http://localhost:3000**.

Alternatively, start Rails alone:

```bash
bin/rails server
```

### Step 6: Install the Chrome Extension (optional)

1. Open Chrome and go to `chrome://extensions`
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select the `chrome_extension/` folder
4. Click the extension icon → **Options** → set:
   - **API URL**: `http://localhost:3000`
   - **API Token**: copy from your user profile page (auto-generated on sign-up)
5. Visit any web page, select text, and click the floating "Q" button

### Verify everything works

```bash
# Open Rails console
bin/rails console

# Check billing mode
BillingService.stub_mode?
# => true (if PAID_API_KEY is not set)
# => false (if PAID_API_KEY is set)

# Test text extraction (requires ANTHROPIC_API_KEY)
result = TextExtractor.call("path/to/any/file.pdf")
result.clean_text
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Claude API key for text extraction, transformation, chat, and summarization |
| `ELEVENLABS_API_KEY` | No | ElevenLabs API key for TTS. Falls back to browser Speech Synthesis when unset |
| `PAID_API_KEY` | No | Paid.ai API key for billing. Runs in stub mode (all requests allowed) when unset |
| `PAID_FAIL_OPEN` | No | Default `true`. Allow requests to proceed if the billing API is unreachable |

## Deploying to Render

The project includes a `render.yaml` Blueprint for one-click deployment:

1. Go to [dashboard.render.com](https://dashboard.render.com) → **New** → **Blueprint**
2. Connect the GitHub repo (`ecemguvener/Hackeurope-Paris-2026`), branch `main`
3. Set the secret environment variables when prompted:
   - `RAILS_MASTER_KEY` — from `config/master.key`
   - `ANTHROPIC_API_KEY`
   - `ELEVENLABS_API_KEY`
   - `PAID_API_KEY`
4. Click **Apply** — Render creates the PostgreSQL database and web service, runs migrations, and starts Puma

## Text Extraction

| Input | Method |
|---|---|
| `.png` `.jpg` `.jpeg` `.webp` | Claude vision (direct) |
| `.pdf` with a text layer | `pdf-reader` gem (fast, offline) |
| Scanned / image-only PDF | Each page rendered to PNG, then Claude vision |

Every extraction produces three outputs:

- **raw_text** — verbatim text as extracted
- **clean_text** — hyphenation fixed, whitespace normalised
- **readable_text** — dyslexia-friendly: short chunks, bullet lists, section separators

### CLI Usage

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

### Using the Services in Ruby

```ruby
# Text extraction
result = TextExtractor.call("path/to/file.pdf")
result.raw_text       # verbatim
result.clean_text     # normalised
result.readable_text  # dyslexia-friendly

# Extraction + speech
result = TextExtractor.call("path/to/file.pdf", speech_enabled: true, voice: "rachel", speed: 1.0)
result.audio_url      # "/audio/abc123.mp3"

# Generate speech from any text
tts = TTSService.speak("Hello world", voice: "aria", speed: 1.0)
tts.audio_url         # "/audio/abc123.mp3"

# Available voices
TTSService::VOICES.keys  # ["rachel", "aria", "roger", "sarah", "george"]

# Reformat text independently
DyslexiaFormatter.format(some_text)

# Clean text independently
TextCleaner.clean(some_text)
```

## Running Tests

```bash
bundle exec rspec
```

## License

Built at Hack Europe Paris 2026.
