---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-02-21'
inputDocuments:
  - docs/planning-artifacts/product-brief-hackeurope-2026-02-21.md
  - docs/planning-artifacts/prd.md
  - docs/brainstorming/brainstorming-session-2026-02-21.md
workflowType: 'architecture'
project_name: 'hackeurope'
user_name: 'team'
date: '2026-02-21'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
28 FRs across 6 domains. The heaviest architectural weight falls on Content Transformation (FR5-FR10) — this is the core pipeline where superposition resolution, Claude semantic rewriting, and original preservation all intersect. Profile Onboarding (FR1-FR4) is the second critical domain — a stateful conversational agent with structured extraction via Claude tool_use. TTS (FR11-FR13), Readability Analysis (FR14-FR16), Content Presentation (FR17-FR20), and Value Metrics (FR21-FR28) are architecturally simpler but create cross-cutting dependencies.

**Non-Functional Requirements:**
15 NFRs driving architecture. The most impactful: sub-3s transformation latency (NFR1) constrains the pipeline design — Claude + ReadabilityScorer + content-type detection must all complete within budget. ElevenLabs TTS streaming within 1.5s (NFR3) means audio must be async/parallel, not sequential. LangSmith must never block user paths (NFR13). WCAG 2.1 AA (NFR6-NFR10) is a firm constraint on all frontend work.

**Scale & Complexity:**

- Primary domain: Web App + API Backend (Rails 7+ monolith)
- Complexity level: Medium
- Estimated architectural components: ~12 (2 agents, 3 tool services, 4 API endpoints, 1 data model, 1 frontend, 1 observability layer)

### Technical Constraints & Dependencies

- **Ruby on Rails 7+** with Hotwire (Turbo Frames + Stimulus) — no SPA framework
- **Claude API** via `anthropic` Ruby gem with `tool_use` — backbone for both agents
- **ElevenLabs TTS API** — REST API with audio streaming to browser
- **LangSmith** — via `langsmithrb_rails` gem or REST API / OpenTelemetry fallback
- **PostgreSQL** with `jsonb` columns for profiles and superposition states
- **No authentication** for MVP — single demo user, hardcoded user_id
- **Content size limit:** 5000 characters per transformation
- **Concurrency:** 1 user (hackathon demo)

### Cross-Cutting Concerns Identified

1. **Asymmetric Error Resilience** — Claude failure returns original content; ElevenLabs failure falls back to Web Speech API; LangSmith failure is silent. Each external dependency has a different degradation strategy.
2. **Observability as Non-Blocking Enhancement** — LangSmith traces every operation but must never add latency or block the user-facing pipeline. Local cost calculation as backup (NFR15).
3. **Dual Cost Tracking** — Claude API cost + ElevenLabs TTS cost must both be calculated, stored, and displayed per transformation.
4. **Original Content Preservation** — Every transformation stores and serves the original alongside the transformed version. The toggle pattern (FR18) is safety-critical for user trust.
5. **Profile Resolution Gate** — Content type detection (lightweight classifier) must execute before transformation and before TTS to resolve the correct superposition state. This is a shared decision point.
6. **Streaming vs. Blocking Responses** — Text transformation is synchronous/blocking; TTS audio is streaming/async. The response model must handle both patterns for the same user action.

## Starter Template Evaluation

### Primary Technology Domain

Web App + API Backend (Rails monolith) based on PRD requirements — Hotwire frontend + JSON API endpoints serving two AI agent services.

### Starter Options Considered

**Option 1: Vanilla `rails new` (Recommended)**
The standard Rails 8 generator with PostgreSQL and Tailwind flags. Rails 8.1 ships with Hotwire (Turbo + Stimulus) built-in, Solid Cache/Queue/Cable, Kamal deployment, and Thruster HTTP/2 proxy. Zero overhead — everything added is something we actually use.

**Option 2: Jumpstart Pro**
Comprehensive SaaS template with authentication, multitenancy, Stripe/PayPal integration, admin dashboards. Updated for Rails 8.1. **Rejected** — adds auth, payments, and multi-tenant complexity that is explicitly out of scope for MVP. Would add overhead without value for a single-user hackathon demo.

**Option 3: Bullet Train**
MIT-licensed Rails framework with Super Scaffolding, Devise auth, team management. **Rejected** — same reasoning as Jumpstart Pro. Authentication and team features are post-MVP concerns.

**Option 4: Railway Rails 8 Starter**
Prewired for Railway deployment with Solid Stack + PostgreSQL + Docker. Interesting if deploying to Railway, but locks in deployment target prematurely.

### Selected Starter: Vanilla `rails new` with flags

**Rationale for Selection:**
- Hackathon MVP needs speed and simplicity, not SaaS scaffolding
- No authentication, payments, or multi-tenancy needed — premium starters add dead weight
- Rails 8.1 ships Hotwire by default — exactly what the PRD specifies
- Tailwind CSS provides rapid UI development + WCAG-friendly utilities for the accessibility-focused product
- Clean starting point means every dependency is intentional and understood
- RSpec added separately for testing (industry standard over Minitest for larger service object architectures)

**Initialization Command:**

```bash
# Requires Ruby 3.4.x and Rails 8.1.2
rails new qlarity --database=postgresql --css=tailwind --skip-test

cd qlarity

# Add RSpec for testing
bundle add rspec-rails --group "development,test"
rails generate rspec:install
```

### Architectural Decisions Provided by Starter

**Language & Runtime:**
- Ruby 3.4.x / Rails 8.1.2
- Importmap for JavaScript (Rails 8 default — no Node.js build step needed)

**Styling Solution:**
- Tailwind CSS via `--css=tailwind` flag
- Utility-first approach ideal for rapid prototyping and WCAG color contrast compliance

**Build Tooling:**
- Propshaft asset pipeline (Rails 8 default)
- Importmap for JS — zero-config, no webpack/esbuild
- Tailwind CSS CLI for stylesheet compilation

**Testing Framework:**
- RSpec (added separately, replacing default Minitest)
- Rails 8 ships with Brakeman for security scanning and RuboCop for linting by default

**Code Organization:**
- Standard Rails MVC + `app/services/` for agent service objects
- `app/services/onboarding_agent.rb`, `app/services/transform_agent.rb`
- Tool services: `app/services/tools/text_simplifier.rb`, etc.
- PostgreSQL with `jsonb` columns for flexible profile storage

**Development Experience:**
- Hotwire (Turbo Frames + Stimulus) built-in — no separate install
- Rails 8 Solid Cable for Action Cable (WebSocket support if needed)
- GitHub Actions CI workflow generated by default
- Docker + Kamal deployment scaffolding included

**Note:** Project initialization using this command should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Data modeling: User + Transformation models with `jsonb` columns
- API namespace: `/api/v1/` RESTful JSON endpoints
- Service object pattern: agents and tools under `app/services/`
- Environment variable management for 3 external API keys

**Important Decisions (Shape Architecture):**
- Standardized error response format
- Stimulus controller organization (4 controllers)
- Turbo Frame-based partial updates
- Audio playback architecture with fallback chain

**Deferred Decisions (Post-MVP):**
- Deployment target and hosting strategy
- Authentication and authorization
- Caching strategy
- Rate limiting
- CI/CD pipeline configuration

### Data Architecture

- **Database:** PostgreSQL (decided in starter)
- **Models:** `User` (profile + superposition_states as `jsonb`), `Transformation` (original, transformed, metrics, content_type, content_hash as `jsonb` + indexed columns)
- **Content Hashing:** SHA-256 hash on original content for duplicate detection (FR16 re-read measurement)
- **Schema Flexibility:** `jsonb` columns for profile and metrics — no migrations needed when profile schema evolves
- **Caching:** Deferred — Rails default in-memory cache sufficient for single-user MVP
- **Seeding:** `db/seeds.rb` creates hardcoded `demo_user` with default profile

### Authentication & Security

- **MVP:** No authentication. Single demo user seeded in database. All endpoints open.
- **API Key Management:** `dotenv-rails` gem for local development (`.env` file with `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`, `LANGSMITH_API_KEY`). Platform environment variables for production.
- **Input Validation:** Content length validation (max 5000 chars) at controller level. Reject empty content submissions.
- **Future-proofing:** Controllers namespaced under `Api::V1::` so auth middleware can be inserted later without route changes.

### API & Communication Patterns

- **Design:** RESTful JSON API under `/api/v1/` namespace
- **Endpoints:** 4 endpoints as defined in PRD (`POST onboarding`, `POST transform`, `GET profile`, `GET metrics`)
- **Error Format:** Standardized `{ error: { code: string, message: string, details?: {} } }` with HTTP status codes (400 bad request, 422 unprocessable, 500 internal, 503 service unavailable for API failures)
- **Content-Type:** `application/json` for all API responses
- **Rate Limiting:** Deferred — not needed for single-user MVP
- **Dual response path:** API endpoints return JSON; web views use Turbo Frames for HTML partial updates

### Frontend Architecture

- **Framework:** Hotwire — Turbo Frames for partial updates, Stimulus for behavior (decided in starter)
- **Turbo Frames:** `onboarding_conversation` (chat turns), `transformation_result` (before/after content), `metrics_panel` (per-transformation stats)
- **Stimulus Controllers:**
  - `onboarding_controller.js` — conversation flow, progress indicator, profile completion state
  - `transform_controller.js` — content submission, toggle between original/transformed views, loading states
  - `audio_controller.js` — TTS playback (play/pause/stop), ElevenLabs streaming via HTML5 `<audio>`, automatic fallback to Web Speech API on failure
  - `metrics_controller.js` — per-transformation and aggregate value metrics display
- **Toggle Pattern:** Client-side CSS class toggle between original and transformed content (NFR4: instant, no server round-trip)
- **Accessibility:** Tailwind utilities for WCAG 2.1 AA color contrast, keyboard navigation via semantic HTML + `tabindex`, `aria-` attributes on audio controls

### Infrastructure & Deployment

- **Deployment:** Deferred — to be decided closer to demo day
- **Environment Configuration:** `dotenv-rails` for local development; platform env vars for production
- **CI/CD:** Deferred — GitHub Actions scaffold available from Rails 8 default when needed
- **Monitoring:** LangSmith serves as primary observability layer; Rails default logging for application-level monitoring

### Decision Impact Analysis

**Implementation Sequence:**
1. Rails project initialization (starter command)
2. Database models + migrations (`User`, `Transformation`)
3. Seed data (demo user)
4. Service objects (`OnboardingAgent`, `TransformAgent`, tools)
5. API controllers under `Api::V1::` namespace
6. Frontend views with Turbo Frames
7. Stimulus controllers for interactivity
8. TTS integration with fallback
9. LangSmith tracing layer

**Cross-Component Dependencies:**
- TransformAgent depends on User profile (must exist before transformation)
- Audio controller depends on TransformAgent output (transformed text feeds TTS)
- Metrics display depends on both Claude and ElevenLabs cost calculations
- Content hash (Transformation model) enables FR16 re-read detection across the metrics endpoint
- Superposition resolution is shared logic used by both TransformAgent and content-type detection

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 18 areas where AI agents could make different choices, organized into 5 categories.

### Naming Patterns

**Database Naming Conventions (Rails Standard — enforce strictly):**
- Tables: `snake_case`, plural (`users`, `transformations`)
- Columns: `snake_case` (`content_type`, `user_id`, `created_at`)
- Foreign keys: `{table_singular}_id` (`user_id`)
- JSON columns: `snake_case` keys internally (`superposition_states`, not `superpositionStates`)
- Indexes: Rails auto-generated names (`index_transformations_on_user_id`)

**API Naming Conventions:**
- Endpoints: `/api/v1/{resource}` — plural nouns, `snake_case` (`/api/v1/transformations`, not `/api/v1/transform`)
- Exception: `POST /api/v1/onboarding` (action endpoint, not CRUD resource)
- Query parameters: `snake_case` (`?user_id=`, `?content_type=`)
- JSON response keys: `snake_case` throughout (`readability_before`, not `readabilityBefore`)
- Headers: Standard HTTP headers only — no custom `X-` headers for MVP

**Code Naming Conventions (Ruby Standard):**
- Classes/Modules: `PascalCase` (`OnboardingAgent`, `TextSimplifier`)
- Methods/Variables: `snake_case` (`transform_content`, `user_profile`)
- Constants: `SCREAMING_SNAKE_CASE` (`MAX_CONTENT_LENGTH = 5000`)
- Files: `snake_case.rb` matching class name (`onboarding_agent.rb`)
- Stimulus controllers: `kebab-case` in HTML (`data-controller="transform"`) mapping to `snake_case` files (`transform_controller.js`)
- Turbo Frame IDs: `snake_case` (`onboarding_conversation`, `transformation_result`)

### Structure Patterns

**Project Organization:**

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       ├── onboarding_controller.rb
│   │       ├── transformations_controller.rb
│   │       ├── profiles_controller.rb
│   │       └── metrics_controller.rb
│   ├── pages_controller.rb          # web demo views
│   └── application_controller.rb
├── models/
│   ├── user.rb
│   └── transformation.rb
├── services/
│   ├── onboarding_agent.rb
│   ├── transform_agent.rb
│   ├── content_classifier.rb        # superposition resolver
│   └── tools/
│       ├── text_simplifier.rb
│       ├── sentence_splitter.rb
│       └── readability_scorer.rb
├── clients/                          # external API wrappers
│   ├── claude_client.rb
│   ├── elevenlabs_client.rb
│   └── langsmith_client.rb
├── views/
│   ├── pages/
│   │   ├── onboarding.html.erb
│   │   └── demo.html.erb
│   └── layouts/
├── javascript/
│   └── controllers/                  # Stimulus controllers
│       ├── onboarding_controller.js
│       ├── transform_controller.js
│       ├── audio_controller.js
│       └── metrics_controller.js
spec/
├── services/
│   ├── onboarding_agent_spec.rb
│   ├── transform_agent_spec.rb
│   ├── content_classifier_spec.rb
│   └── tools/
│       ├── text_simplifier_spec.rb
│       ├── sentence_splitter_spec.rb
│       └── readability_scorer_spec.rb
├── clients/
│   ├── claude_client_spec.rb
│   ├── elevenlabs_client_spec.rb
│   └── langsmith_client_spec.rb
├── requests/                         # API integration tests
│   └── api/
│       └── v1/
│           ├── onboarding_spec.rb
│           ├── transformations_spec.rb
│           ├── profiles_spec.rb
│           └── metrics_spec.rb
└── models/
    ├── user_spec.rb
    └── transformation_spec.rb
```

**Key structural rules:**
- Service objects in `app/services/` — never in models or controllers
- External API wrappers in `app/clients/` — never call APIs directly from services
- Tool services namespaced under `app/services/tools/` — all transformation tools live here
- Tests mirror `app/` structure under `spec/`
- API request specs in `spec/requests/api/v1/` — not controller specs

### Format Patterns

**API Response Formats:**

Success response:
```json
{
  "data": { "..." },
  "meta": { "timestamp": "2026-02-21T15:00:00Z" }
}
```

Error response:
```json
{
  "error": {
    "code": "content_too_long",
    "message": "Content exceeds 5000 character limit",
    "details": { "length": 5432, "max": 5000 }
  }
}
```

Transformation response (specific):
```json
{
  "data": {
    "original": "...",
    "transformed": "...",
    "content_type_detected": "technical",
    "superposition_state_used": "technical",
    "metrics": {
      "readability_before": 14.2,
      "readability_after": 9.8,
      "readability_delta": -4.4,
      "cost_usd": 0.003,
      "latency_ms": 1800,
      "tokens_used": 450
    },
    "tts": {
      "audio_url": "/api/v1/audio/abc123",
      "tts_cost_usd": 0.001
    }
  }
}
```

**Data Format Rules:**
- All JSON keys: `snake_case`
- Dates: ISO 8601 strings (`"2026-02-21T15:00:00Z"`)
- Booleans: `true`/`false` (never `1`/`0`)
- Nulls: Use `null` explicitly, never omit the key
- Money: Float with currency suffix in key name (`cost_usd: 0.003`)
- Durations: Integer milliseconds with `_ms` suffix (`latency_ms: 1800`)

### Communication Patterns

**External API Client Pattern:**

Every external API gets a dedicated client class in `app/clients/`:

```ruby
class ClaudeClient
  def initialize
    @api_key = ENV.fetch("ANTHROPIC_API_KEY")
  end

  def chat(messages:, tools: [], system: nil)
    # Returns parsed response or raises ClaudeClient::Error
  end
end
```

Rules:
- Clients raise custom error classes (`ClaudeClient::Error`, `ElevenlabsClient::Error`)
- Services catch client errors and implement fallback logic
- Clients handle HTTP concerns only — no business logic
- Clients are initialized with ENV vars — never accept API keys as params

**LangSmith Tracing Pattern:**

Tracing wraps service calls, never blocks them:

```ruby
class TransformAgent
  def call(user:, content:)
    result = perform_transformation(user, content)
    trace_async(result)  # non-blocking
    result
  rescue LangsmithClient::Error
    # silently continue — tracing never blocks user path
  end
end
```

### Process Patterns

**Error Handling — Asymmetric Degradation:**

| Failure | Response | User Impact |
|---|---|---|
| Claude API failure | Return original content + error status | "Transformation unavailable" message, content still visible |
| ElevenLabs failure | Fall back to Web Speech API | TTS still works, lower voice quality |
| LangSmith failure | Log locally, continue | Zero user impact — silent |
| Invalid input | 422 with error details | Clear validation message |
| Unknown error | 500 with generic message | "Something went wrong" — log full error server-side |

**Service Object Pattern:**

All service objects follow the same interface:

```ruby
class TransformAgent
  def initialize(user:, content:)
    @user = user
    @content = content
  end

  def call
    # Returns a Result object or hash
    # Raises specific errors for caller to handle
  end
end

# Usage: TransformAgent.new(user: user, content: content).call
```

Rules:
- Constructor receives dependencies, `call` executes
- Return structured data (hash or Result object), never raw API responses
- Raise domain-specific errors, never let raw HTTP errors escape

**Loading States (Stimulus):**

```javascript
// Pattern: data-transform-target="submitButton"
// During load: button disabled, spinner shown
// On success: result frame swaps
// On error: error message displayed, button re-enabled
```

Rules:
- Loading state managed in Stimulus controller, never in server response
- Use Turbo Frame `loading="lazy"` where appropriate
- All async actions show loading indicator within 100ms

### Enforcement Guidelines

**All AI Agents MUST:**

1. Follow Rails naming conventions — `snake_case` everywhere except class names (`PascalCase`)
2. Place service objects in `app/services/`, API clients in `app/clients/`, tools in `app/services/tools/`
3. Wrap all external API calls in client classes — never call APIs directly from services or controllers
4. Return `{ data: ... }` wrapper on all success API responses and `{ error: ... }` on all failures
5. Use `snake_case` for all JSON keys in API requests and responses
6. Write RSpec tests mirroring the `app/` directory structure under `spec/`
7. Never let LangSmith tracing block the user-facing request path
8. Always preserve original content alongside transformations
9. Use `ENV.fetch("KEY")` for required env vars (raises on missing) — never `ENV["KEY"]`

**Anti-Patterns to Avoid:**
- Putting business logic in controllers (use service objects)
- Calling Claude/ElevenLabs/LangSmith APIs directly without client wrapper
- Using `camelCase` in JSON responses
- Letting observability failures propagate to users
- Storing API keys anywhere except environment variables
- Writing controller specs instead of request specs

## Project Structure & Boundaries

### Complete Project Directory Structure

```
qlarity/
├── .env.example                      # Template for required env vars
├── .env                              # Local dev env vars (gitignored)
├── .gitignore
├── .github/
│   └── workflows/
│       └── ci.yml                    # RSpec + RuboCop + Brakeman
├── .rubocop.yml                      # Linting config
├── .ruby-version                     # Ruby 3.4.x
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── Procfile                          # Thruster + Rails server
├── Dockerfile                        # Kamal deployment
├── config.ru
│
├── config/
│   ├── application.rb
│   ├── database.yml                  # PostgreSQL config
│   ├── routes.rb                     # All route definitions
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   ├── initializers/
│   │   ├── claude.rb                 # Claude API client config
│   │   ├── elevenlabs.rb            # ElevenLabs client config
│   │   └── langsmith.rb            # LangSmith tracing config
│   └── locales/
│       └── en.yml
│
├── db/
│   ├── migrate/
│   │   ├── XXXXXX_create_users.rb
│   │   └── XXXXXX_create_transformations.rb
│   ├── schema.rb
│   └── seeds.rb                      # Demo user + sample data
│
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── pages_controller.rb       # Web demo: onboarding + transform views
│   │   └── api/
│   │       └── v1/
│   │           ├── base_controller.rb        # JSON rendering, error handling
│   │           ├── onboarding_controller.rb  # POST /api/v1/onboarding
│   │           ├── transformations_controller.rb  # POST /api/v1/transformations
│   │           ├── profiles_controller.rb    # GET /api/v1/profiles
│   │           └── metrics_controller.rb     # GET /api/v1/metrics
│   │
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── user.rb                   # profile:jsonb, superposition_states:jsonb
│   │   └── transformation.rb         # original, transformed, metrics:jsonb, content_hash
│   │
│   ├── services/
│   │   ├── onboarding_agent.rb       # Conversational profile builder (Claude tool_use)
│   │   ├── transform_agent.rb        # Orchestrates transformation pipeline
│   │   ├── content_classifier.rb     # Detects content type, resolves superposition state
│   │   └── tools/
│   │       ├── text_simplifier.rb    # Claude semantic rewriting
│   │       ├── sentence_splitter.rb  # Breaks complex sentences
│   │       └── readability_scorer.rb # Flesch-Kincaid before/after scoring
│   │
│   ├── clients/
│   │   ├── claude_client.rb          # Anthropic API wrapper
│   │   ├── elevenlabs_client.rb      # ElevenLabs TTS API wrapper
│   │   └── langsmith_client.rb       # LangSmith tracing wrapper
│   │
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb  # Main layout with Tailwind + meta tags
│   │   └── pages/
│   │       ├── onboarding.html.erb   # Gamified onboarding UI
│   │       ├── demo.html.erb         # Transform demo: paste, transform, toggle, listen
│   │       └── _metrics_panel.html.erb  # Partial: per-transformation value metrics
│   │
│   ├── javascript/
│   │   ├── application.js            # Importmap entry point
│   │   └── controllers/
│   │       ├── index.js              # Stimulus controller registration
│   │       ├── onboarding_controller.js   # Conversation flow + progress
│   │       ├── transform_controller.js    # Submit, toggle, loading states
│   │       ├── audio_controller.js        # TTS playback + Web Speech fallback
│   │       └── metrics_controller.js      # Value metrics display
│   │
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   └── application.tailwind.css   # Tailwind directives + custom styles
│   │   └── images/
│   │       └── logo.svg
│   │
│   └── helpers/
│       └── application_helper.rb
│
├── spec/
│   ├── spec_helper.rb
│   ├── rails_helper.rb
│   ├── models/
│   │   ├── user_spec.rb
│   │   └── transformation_spec.rb
│   ├── services/
│   │   ├── onboarding_agent_spec.rb
│   │   ├── transform_agent_spec.rb
│   │   ├── content_classifier_spec.rb
│   │   └── tools/
│   │       ├── text_simplifier_spec.rb
│   │       ├── sentence_splitter_spec.rb
│   │       └── readability_scorer_spec.rb
│   ├── clients/
│   │   ├── claude_client_spec.rb
│   │   ├── elevenlabs_client_spec.rb
│   │   └── langsmith_client_spec.rb
│   ├── requests/
│   │   └── api/
│   │       └── v1/
│   │           ├── onboarding_spec.rb
│   │           ├── transformations_spec.rb
│   │           ├── profiles_spec.rb
│   │           └── metrics_spec.rb
│   ├── fixtures/
│   │   ├── sample_slack_message.txt
│   │   ├── sample_jira_ticket.txt
│   │   └── sample_short_message.txt
│   └── support/
│       ├── api_helpers.rb            # Shared request spec helpers
│       └── claude_mock_helpers.rb    # Claude API response stubs
│
└── public/
    ├── favicon.ico
    └── robots.txt
```

### Architectural Boundaries

**API Boundaries:**
- `Api::V1::BaseController` — all API controllers inherit from this. Handles JSON rendering, error formatting (`{ data }` / `{ error }`), parameter validation, and content-type enforcement.
- Web views via `PagesController` — completely separate from API. Uses Turbo Frames for partial updates. Never shares controller logic with API.
- Routes: `/api/v1/*` for JSON API, `/onboarding` and `/demo` for web views.

**Service Boundaries:**
- Controllers ONLY call service objects — never contain business logic
- Services ONLY call clients for external APIs — never make HTTP calls directly
- Tools (`app/services/tools/`) are called exclusively by `TransformAgent` — never by controllers or other services
- `ContentClassifier` is called by `TransformAgent` before any tool execution

**Client Boundaries:**
- Each external API has exactly one client class in `app/clients/`
- Clients handle: HTTP connection, authentication, request/response serialization, timeout enforcement, custom error raising
- Clients do NOT handle: retry logic, fallback behavior, business decisions — those belong in services

**Data Boundaries:**
- Models handle: validations, associations, scopes, JSON serialization of `jsonb` columns
- Models do NOT handle: external API calls, business logic, transformation logic
- `jsonb` columns are the flexibility boundary — profile schema changes don't require migrations

### Requirements to Structure Mapping

**FR1-FR4 (Profile Onboarding):**
- Service: `app/services/onboarding_agent.rb`
- Client: `app/clients/claude_client.rb` (tool_use for structured extraction)
- Model: `app/models/user.rb` (profile + superposition_states storage)
- API: `app/controllers/api/v1/onboarding_controller.rb`
- View: `app/views/pages/onboarding.html.erb`
- JS: `app/javascript/controllers/onboarding_controller.js`

**FR5-FR10 (Content Transformation):**
- Service: `app/services/transform_agent.rb` (orchestrator)
- Classifier: `app/services/content_classifier.rb` (superposition resolution)
- Tools: `app/services/tools/text_simplifier.rb`, `sentence_splitter.rb`
- Client: `app/clients/claude_client.rb` (semantic rewriting)
- Model: `app/models/transformation.rb` (stores original + transformed + metrics)
- API: `app/controllers/api/v1/transformations_controller.rb`

**FR11-FR13 (Text-to-Speech):**
- Client: `app/clients/elevenlabs_client.rb`
- JS: `app/javascript/controllers/audio_controller.js` (playback + Web Speech fallback)
- View: Audio controls embedded in `demo.html.erb`

**FR14-FR16 (Readability Analysis):**
- Tool: `app/services/tools/readability_scorer.rb` (Flesch-Kincaid calculation — pure Ruby, no API)
- Model: `app/models/transformation.rb` (stores readability_before, readability_after, content_hash)

**FR17-FR20 (Content Presentation):**
- View: `app/views/pages/demo.html.erb` (messaging-style UI, toggle, before/after)
- JS: `app/javascript/controllers/transform_controller.js` (toggle logic)
- CSS: `app/assets/stylesheets/application.tailwind.css` (WCAG-compliant styles)

**FR21-FR28 (Value Metrics & Observability):**
- Client: `app/clients/langsmith_client.rb` (tracing)
- API: `app/controllers/api/v1/metrics_controller.rb` (aggregate queries)
- View: `app/views/pages/_metrics_panel.html.erb` (per-transformation display)
- JS: `app/javascript/controllers/metrics_controller.js`

### Cross-Cutting Concerns Mapping

**Error Handling:** `Api::V1::BaseController` + each client's custom error class
**LangSmith Tracing:** `app/clients/langsmith_client.rb` called from services via `trace_async`
**Cost Tracking:** Calculated in `TransformAgent` (Claude) and `audio_controller.js` (ElevenLabs), stored in `Transformation.metrics`
**Original Preservation:** Enforced in `Transformation` model — `original` column is non-nullable

### Integration Points

**Internal Communication:**
```
PagesController → OnboardingAgent → ClaudeClient → Anthropic API
                                   ↓
                                   User.update(profile)

PagesController → TransformAgent → ContentClassifier (resolves state)
                                 → Tools::TextSimplifier → ClaudeClient
                                 → Tools::SentenceSplitter → ClaudeClient
                                 → Tools::ReadabilityScorer (local calculation)
                                 → Transformation.create(result)
                                 → LangsmithClient.trace_async(metadata)

audio_controller.js → ElevenlabsClient (streaming audio)
                    → Web Speech API (fallback)
```

**External Integrations:**

| Integration | Client | Config | Timeout |
|---|---|---|---|
| Claude API (Anthropic) | `app/clients/claude_client.rb` | `config/initializers/claude.rb` | 5s |
| ElevenLabs TTS | `app/clients/elevenlabs_client.rb` | `config/initializers/elevenlabs.rb` | 3s |
| LangSmith | `app/clients/langsmith_client.rb` | `config/initializers/langsmith.rb` | 2s |

**Data Flow:**
```
User Input (text) → Controller → TransformAgent
  → ContentClassifier: detect type → resolve superposition state
  → TextSimplifier: Claude rewrites per profile + state
  → SentenceSplitter: break complex sentences
  → ReadabilityScorer: Flesch-Kincaid before/after
  → Transformation.create: persist original + transformed + metrics
  → LangSmith: trace metadata (async, non-blocking)
  → Response: { data: { original, transformed, metrics, tts } }
```

## Architecture Validation Results

### Coherence Validation

**Decision Compatibility:** All technology choices verified compatible — Rails 8.1.2 with Ruby 3.4.x, PostgreSQL jsonb, Hotwire, Tailwind CSS, Importmap, Propshaft. Claude API anthropic gem, ElevenLabs REST, LangSmith tracing all integrate via standard HTTP clients in Ruby. No version conflicts detected.

**Pattern Consistency:** Service object pattern (initialize + call), client wrapper pattern, and tool pattern are applied uniformly. All naming follows Rails conventions. JSON API format (`{ data }` / `{ error }`) is consistent across all 4+1 endpoints.

**Structure Alignment:** Project directory structure directly supports all architectural decisions. Clear boundaries between controllers, services, clients, and tools. Test structure mirrors app structure.

### Requirements Coverage Validation

**Functional Requirements:** All 28 FRs (FR1-FR28) mapped to specific architectural components with identified files and directories. Every FR category has a clear implementation path through the service object → client → external API chain.

**Non-Functional Requirements:** All 15 NFRs (NFR1-NFR15) addressed architecturally. Performance budgets enforced via client timeouts. WCAG compliance addressed via Tailwind utilities and semantic HTML. Integration reliability via asymmetric degradation strategy per external dependency.

### Implementation Readiness Validation

**Decision Completeness:** All critical and important decisions documented with specific versions (Ruby 3.4.x, Rails 8.1.2). Deferred decisions (deployment, auth, caching, CI/CD) are explicitly marked as post-MVP and do not block implementation.

**Structure Completeness:** Complete directory tree with ~60 specific files defined. Every file has a clear purpose and maps to specific FRs.

**Pattern Completeness:** Naming, structure, format, communication, and process patterns all defined with concrete examples and anti-patterns.

### Gap Analysis Results

**Important (resolved):**
- TTS audio streaming endpoint was missing → resolved by adding `GET /api/v1/audio/:transformation_id` as server-side proxy to ElevenLabs

**Minor (acceptable for MVP):**
- No re-onboarding flow (profile reset requires re-seeding)
- No profile editing endpoint (onboarding is the only profile creation path)
- No WebSocket architecture (not needed for paste-and-transform model)

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed (28 FRs, 15 NFRs)
- [x] Scale and complexity assessed (medium, ~12 components)
- [x] Technical constraints identified (3 external APIs, no auth, 5000 char limit)
- [x] Cross-cutting concerns mapped (6 concerns identified)

**Architectural Decisions**
- [x] Critical decisions documented with versions (Ruby 3.4.x, Rails 8.1.2, PostgreSQL)
- [x] Technology stack fully specified (9 technology choices)
- [x] Integration patterns defined (3 external APIs with timeout/fallback strategies)
- [x] Performance considerations addressed (sub-3s transform, async TTS, non-blocking tracing)

**Implementation Patterns**
- [x] Naming conventions established (database, API, code)
- [x] Structure patterns defined (services, clients, tools separation)
- [x] Communication patterns specified (client wrapper, async tracing)
- [x] Process patterns documented (error handling, service object interface, loading states)

**Project Structure**
- [x] Complete directory structure defined (~60 files)
- [x] Component boundaries established (controller/service/client/tool)
- [x] Integration points mapped (internal flow + 3 external APIs)
- [x] Requirements to structure mapping complete (all 6 FR categories)

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High — all requirements covered, no critical gaps, well-defined patterns

**Key Strengths:**
- Clean separation of concerns (controllers → services → clients) prevents coupling
- Asymmetric error degradation ensures graceful failure across all external dependencies
- Superposition profile model has clear resolution path via ContentClassifier
- LangSmith tracing as non-blocking enhancement means observability never hurts user experience
- Comprehensive naming and format patterns prevent AI agent implementation conflicts

**Areas for Future Enhancement:**
- Authentication layer (post-MVP)
- Profile editing and re-onboarding flows
- Implicit feedback loop for profile refinement
- Caching layer for repeated transformations
- WebSocket support for real-time transformation (Chrome extension use case)

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Use implementation patterns consistently across all components
- Respect project structure and boundaries (services, clients, tools separation)
- Refer to this document for all architectural questions
- When in doubt, follow Rails conventions

**First Implementation Priority:**
```bash
rails new qlarity --database=postgresql --css=tailwind --skip-test
```
