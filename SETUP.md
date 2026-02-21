# Qlarity — Setup Guide

Qlarity transforms documents and web pages into dyslexia-friendly text using Claude AI and ElevenLabs TTS. It consists of a **Rails web app** and a **Chrome extension**.

---

## Prerequisites

- **Ruby** 3.4.8 (managed via rbenv, asdf, or mise)
- **PostgreSQL** (running locally)
- **Bundler** (`gem install bundler`)
- **Foreman** (installed automatically by `bin/dev`)
- **Google Chrome** (for the extension)

API keys (free tiers work):
- [Anthropic API key](https://console.anthropic.com/) — powers text transformation, summarization, and chat
- [ElevenLabs API key](https://elevenlabs.io/) — powers text-to-speech

---

## 1. Clone and install

```bash
git clone https://github.com/ecemguvener/Hackeurope-Paris-2026.git
cd Hackeurope-Paris-2026
bundle install
```

## 2. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```
ANTHROPIC_API_KEY=sk-ant-...
ELEVENLABS_API_KEY=sk_...
```

## 3. Set up the database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

The seed output will print your **API token** — copy it, you'll need it for the Chrome extension:

```
Seeded demo user: Demo User
API Token: <your-token-here>
```

If you need to retrieve the token later:

```bash
bin/rails runner "puts User.first.api_token"
```

## 4. Start the web app

```bash
bin/dev
```

This starts the Rails server on **http://localhost:3000** and the Tailwind CSS watcher.

Verify it's running:

```bash
curl http://localhost:3000/up
# Should return 200
```

---

## 5. Install the Chrome Extension

1. Open Chrome and navigate to `chrome://extensions`
2. Enable **Developer mode** (toggle in the top-right corner)
3. Click **Load unpacked**
4. Select the `chrome_extension/` folder from this repo
5. The Qlarity extension icon (purple "Q") appears in your toolbar

## 6. Configure the extension

1. Click the Qlarity extension icon in Chrome
2. Click **Settings** (or right-click the icon → Options)
3. Enter:
   - **Backend URL**: `http://localhost:3000`
   - **API Token**: paste the token from step 3
4. Click **Save Settings** — you should see "Saved! Connection verified."

## 7. Use it

### Web App
- Go to http://localhost:3000
- Upload a document (PDF, image, or text file)
- View transformed versions and listen with text-to-speech

### Chrome Extension
- Visit any web page
- A purple **Q** button appears in the bottom-right corner
- **Select text** on the page — the button pulses to indicate a selection
- **Click the Q button** — the side panel opens with your selected text
- **Right-click selected text** → "Transform with Qlarity" also works

#### Side Panel Tabs

| Tab | What it does |
|---|---|
| **Transform** | Pick a style (Simplified, Bullet Points, Plain Language, Restructured), transform the text, then "Apply to Page" or "Copy" |
| **Chat** | Ask questions about the current page content — Qlarity answers using Claude |
| **Listen** | Choose a voice and speed, then generate speech from any text |

---

## API Endpoints

All endpoints require `Authorization: Bearer <token>` header.

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/transform` | Transform text (params: `text`, `style`) |
| `POST` | `/api/v1/tts` | Text-to-speech (params: `text`, `voice`, `speed`) |
| `POST` | `/api/v1/summarize` | Summarize text (params: `text`) |
| `POST` | `/api/v1/chat` | Chat about content (params: `message`, `page_content`, `history`) |
| `GET` | `/api/v1/profile` | Get user profile |
| `PATCH` | `/api/v1/profile` | Update preferences (params: `preferred_style`, `profile`) |
| `POST` | `/api/v1/interactions` | Save interaction history |

Quick test:

```bash
curl -X POST http://localhost:3000/api/v1/transform \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"text":"Your complex text here","style":"simplified"}'
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `ANTHROPIC_API_KEY is not set` | Check your `.env` file has the key, then restart the server |
| Extension shows "Not connected" | Make sure the Rails server is running on port 3000 and the API token is correct in extension settings |
| TTS fails | Verify `ELEVENLABS_API_KEY` is set in `.env` |
| `PG::ConnectionBad` | Start PostgreSQL: `brew services start postgresql` |
| Extension doesn't appear on page | Refresh the page after installing the extension; it only injects on new page loads |
