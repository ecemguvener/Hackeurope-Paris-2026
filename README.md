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

1. **API keys** – copy `.env.example` to `.env` and fill in your keys:

   ```
   ANTHROPIC_API_KEY=sk-ant-...      # required for image/PDF extraction
   ELEVENLABS_API_KEY=sk-...         # required for speech generation
   PAID_API_URL=https://api.agentpaid.io/api/v1   # omit for stub mode
   PAID_API_KEY=your_paid_key_here
   PAID_COMPANY_ID=demo-company-1    # externalId of customer in Paid.ai
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

## Billing (Paid.ai)

Qlarity enforces per-company usage quotas via [Paid.ai](https://agentpaid.io).

### How it works

| Event | When | Signals sent |
|---|---|---|
| Text extraction | After successful file upload | `text_extraction` (pages, characters) |
| Speech generation | After ElevenLabs TTS call | `tts_generation` (audio_minutes, characters) |

Before each operation Qlarity calls `check_quota`. If the company has exhausted its credits the request is blocked with a clear error message.

### Stub mode (default in dev)

When `PAID_API_URL` is **not set**, billing runs in stub mode:
- All requests are allowed
- Usage is logged locally only
- The Billing dashboard shows a setup guide

```
[BillingService STUB] check_quota company=demo-company-1 → allowed (set PAID_API_URL to enable real billing)
```

### Billing dashboard

Visit `/billing` (or click **Billing** in the nav) to see:
- Company plan and status
- Credits used / available / total
- Entitlement breakdown
- Recent documents

### Setting up a real Paid.ai customer

1. Sign up at [agentpaid.io](https://agentpaid.io) and get an API key
2. Create a Customer with `externalId` matching `PAID_COMPANY_ID` (default: `demo-company-1`)
3. Create an Agent/Product (e.g. "Qlarity") with usage-based pricing attributes
4. Create an Order for the customer linking to that agent with credit entitlements
5. Set env vars and restart:

```bash
PAID_API_URL=https://api.agentpaid.io/api/v1
PAID_API_KEY=your_key_here
PAID_COMPANY_ID=demo-company-1
```

### Using BillingService in Ruby

```ruby
# Check quota before an operation
quota = BillingService.check_quota(BillingService.company_id)
raise "Quota exceeded: #{quota.reason}" unless quota.allowed

# Record usage after success
BillingService.record_usage(
  BillingService.company_id,
  pages:         2,
  characters:    4500,
  audio_minutes: 1.2
)

# Get a full usage summary (for the billing dashboard)
summary = BillingService.usage_summary(BillingService.company_id)
# => { customer_name:, plan:, total:, used:, available:, entitlements:, stub: }

# Check whether billing is in stub mode
BillingService.stub_mode?  # => true if PAID_API_URL is blank
```

### End-to-end demo (curl)

```bash
# Upload a PDF and extract text (quota checked automatically)
curl -s -X POST http://localhost:3000/upload \
  -F "document[file]=@invoice.pdf" \
  -c cookies.txt -b cookies.txt

# Check billing dashboard
curl -s http://localhost:3000/billing \
  -c cookies.txt -b cookies.txt | grep -o 'Credits used.*'
```

Or use the CLI:

```bash
# Extract + speak — both quota check and usage recording happen automatically
bin/extract invoice.pdf --speak --voice=rachel
```

### Fail-open behaviour

`PAID_FAIL_OPEN=true` (default) means if Paid.ai is unreachable, requests are **allowed** and the error is logged. Set to `false` in production to enforce hard limits.

---

## Running tests

```
bundle exec rspec
```

## Starting the development server

```
bin/dev
```
