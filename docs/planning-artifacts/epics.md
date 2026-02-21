---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories]
inputDocuments:
  - docs/planning-artifacts/prd.md
  - docs/planning-artifacts/architecture.md
  - docs/planning-artifacts/product-brief-hackeurope-2026-02-21.md
  - docs/brainstorming/brainstorming-session-2026-02-21.md
---

# hackeurope - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for hackeurope (Qlarity), decomposing the requirements from the PRD and Architecture into implementable stories scoped to the Rails Lead (App + Upload + UI) role.

## Requirements Inventory

### Functional Requirements

**Profile Onboarding (FR1-FR4):**
- FR1: User can initiate an onboarding experience framed as "reading optimization" without any reference to dyslexia or medical conditions
- FR2: User can complete a conversational onboarding flow in 3-5 turns by choosing between paired content samples
- FR3: System can build a structured accessibility profile from onboarding choices (sentence length, font, color overlay, jargon simplification, bullet restructuring, paragraph length, line spacing, keyword highlighting)
- FR4: System can generate multiple superposition states (short_form, long_form, technical) from a single onboarding session

**Content Transformation (FR5-FR10):**
- FR5: User can submit text content (up to 5000 characters) for transformation
- FR6: System can detect the content type of submitted text (short_form, long_form, or technical)
- FR7: System can resolve the appropriate superposition state based on detected content type and user profile
- FR8: System can perform semantic rewriting — breaking complex sentences, replacing jargon, restructuring paragraphs — while preserving original meaning
- FR9: System can apply variable transformation intensity based on resolved superposition state
- FR10: System can preserve original content alongside every transformation

**Text-to-Speech (FR11-FR13):**
- FR11: User can listen to transformed content read aloud via ElevenLabs TTS
- FR12: User can control audio playback (play, pause, stop)
- FR13: System can fall back to browser native Web Speech API if ElevenLabs is unavailable

**Readability Analysis (FR14-FR16):**
- FR14: System can calculate Flesch-Kincaid readability scores before and after transformation
- FR15: System can compute readability delta (grade level improvement) per transformation
- FR16: System can detect duplicate content submissions via content hashing

**Content Presentation (FR17-FR20):**
- FR17: User can view transformed content in a corporate messaging-style interface
- FR18: User can toggle between original and transformed views with one click
- FR19: User can view before/after comparison of content
- FR20: System can apply visual accessibility preferences from profile to transformed view

**Value Metrics & Observability (FR21-FR25):**
- FR21: User can view per-transformation metrics (readability delta, cost, latency, tokens)
- FR22: User can view aggregate metrics across all transformations
- FR23: System can trace every run via LangSmith with tagged metadata
- FR24: System can track ElevenLabs TTS cost per transformation alongside Claude API cost
- FR25: User can view a value dashboard summarizing agent economic impact

**Profile Management (FR26-FR28):**
- FR26: System can store and retrieve user accessibility profile including superposition states
- FR27: User can view their current accessibility profile
- FR28: System can use stored profile for all subsequent transformations without re-onboarding

**Rails Lead Task-Specific Requirements (FR-RL1 through FR-RL7):**
- FR-RL1: Upload flow accepting image, PDF, and text file types
- FR-RL2: File storage via ActiveStorage
- FR-RL3: Results page showing 4 transformation versions side-by-side (tabs/cards layout)
- FR-RL4: "Pick best version" button that collapses superposition to selected style
- FR-RL5: Profile page showing saved user preference (best style)
- FR-RL6: Profile page showing history of transformed documents
- FR-RL7: Route flow: /upload -> /results/:id -> /collapsed/:id

### NonFunctional Requirements

**Performance (NFR1-NFR5):**
- NFR1: Content transformation completes end-to-end in under 3 seconds for up to 5000 characters
- NFR2: Onboarding agent responds to each turn in under 2 seconds
- NFR3: ElevenLabs TTS audio begins streaming within 1.5 seconds
- NFR4: Original/transformed toggle switches instantly (client-side, no server round-trip)
- NFR5: Readability scoring adds no more than 200ms (local computation)

**Accessibility (NFR6-NFR10):**
- NFR6: WCAG 2.1 AA — 4.5:1 color contrast ratio minimum for normal text
- NFR7: All interactive elements keyboard-navigable
- NFR8: Audio playback controls accessible via keyboard and screen reader
- NFR9: Transformed content view respects profile preferences consistently
- NFR10: No content flashes, auto-playing audio, or unexpected layout shifts

**Integration Reliability (NFR11-NFR15):**
- NFR11: Claude API failures return original untransformed content with status message
- NFR12: ElevenLabs failures fall back to Web Speech API transparently
- NFR13: LangSmith tracing failures are silent — never block user pipeline
- NFR14: All external API calls implement timeouts (Claude: 5s, ElevenLabs: 3s, LangSmith: 2s)
- NFR15: Cost tracking remains accurate even when traces fail (local backup calculation)

### Additional Requirements

**From Architecture — Starter Template:**
- Rails 8.1.2 with Ruby 3.4.x: `rails new qlarity --database=postgresql --css=tailwind --skip-test`
- RSpec added separately for testing
- Project initialization is the first implementation story

**From Architecture — Code Organization:**
- Service objects in `app/services/` (OnboardingAgent, TransformAgent, ContentClassifier)
- External API wrappers in `app/clients/` (ClaudeClient, ElevenlabsClient, LangsmithClient)
- Tool services in `app/services/tools/` (TextSimplifier, SentenceSplitter, ReadabilityScorer)
- API controllers under `Api::V1::` namespace
- Stimulus controllers: onboarding, transform, audio, metrics

**From Architecture — Data Model:**
- PostgreSQL with jsonb columns for profile and superposition states
- User model: profile:jsonb, superposition_states:jsonb
- Transformation model: original, transformed, metrics:jsonb, content_hash
- Seed data: demo user via db/seeds.rb

**From Architecture — Patterns:**
- No authentication for MVP — single hardcoded demo user
- dotenv-rails for API keys (ANTHROPIC_API_KEY, ELEVENLABS_API_KEY, LANGSMITH_API_KEY)
- Standardized API response format: { data: {} } / { error: { code, message, details } }
- Hotwire (Turbo Frames + Stimulus) for frontend — no SPA
- Asymmetric error degradation per external dependency
- LangSmith tracing as non-blocking enhancement

**From Architecture — Implementation Sequence:**
1. Rails project initialization (starter command)
2. Database models + migrations (User, Transformation)
3. Seed data (demo user)
4. Service objects (OnboardingAgent, TransformAgent, tools)
5. API controllers under Api::V1:: namespace
6. Frontend views with Turbo Frames
7. Stimulus controllers for interactivity
8. TTS integration with fallback
9. LangSmith tracing layer

### FR Coverage Map

| FR | Epic | Description |
|---|---|---|
| FR5 | Epic 1 | Submit content for transformation (via upload) |
| FR10 | Epic 1 | Preserve original content alongside transformations |
| FR17 | Epic 1 | View content in clean UI interface |
| FR18 | Epic 1 | Toggle between original and transformed views |
| FR19 | Epic 1 | Before/after comparison |
| FR20 | Epic 1 | Apply visual preferences to transformed view |
| FR26 | Epic 1 | Store and retrieve user profile + superposition states |
| FR27 | Epic 1 | View current profile |
| FR-RL1 | Epic 1 | Upload accepting image, PDF, and text |
| FR-RL2 | Epic 1 | File storage via ActiveStorage |
| FR-RL3 | Epic 1 | 4 transformation versions side-by-side (tabs/cards) |
| FR-RL4 | Epic 1 | "Pick best version" collapse button |
| FR-RL5 | Epic 1 | Profile page showing saved best style |
| FR-RL6 | Epic 1 | Profile page showing document history |
| FR-RL7 | Epic 1 | Route flow: /upload -> /results/:id -> /collapsed/:id |

**Note:** FRs owned by other team roles are excluded: AI/Agent Lead (FR1-FR4, FR6-FR9, FR14-FR16), TTS Lead (FR11-FR13), Observability Lead (FR21-FR25, FR28).

## Epic List

### Epic 1: Qlarity Rails Web App — Upload, Transform & Profile

A working end-to-end Rails web application where a user can upload content (image/PDF/text), view 4 transformation versions side-by-side, pick the best version (collapsing the superposition), and see their saved preferences and document history on a profile page.

**User Outcome:** User navigates /upload to submit content, sees results at /results/:id with 4 styled cards, picks preferred version at /collapsed/:id, and views their profile with saved style preference and transformation history.

**FRs covered:** FR5, FR10, FR17, FR18, FR19, FR20, FR26, FR27, FR-RL1, FR-RL2, FR-RL3, FR-RL4, FR-RL5, FR-RL6, FR-RL7

**NFRs addressed:** NFR4, NFR6, NFR7, NFR10

## Epic 1: Qlarity Rails Web App — Upload, Transform & Profile

A working end-to-end Rails web application where a user can upload content (image/PDF/text), view 4 transformation versions side-by-side, pick the best version (collapsing the superposition), and see their saved preferences and document history on a profile page.

### Story 1.1: Rails App Scaffold & Database Foundation

As a developer,
I want a fully initialized Rails application with database models, ActiveStorage, and a seeded demo user,
So that all subsequent stories have a working foundation to build on.

**Acceptance Criteria:**

**Given** no existing Rails application
**When** the developer runs the project initialization commands
**Then** a new Rails 8.1.2 app is created with PostgreSQL, Tailwind CSS, and RSpec configured
**And** ActiveStorage is installed and configured for local file storage
**And** a `User` model exists with `profile:jsonb` and `superposition_states:jsonb` columns
**And** a `Document` model exists with references to `User`, `original_content:text`, `extracted_text:text`, `transformations:jsonb` (stores 4 versions), `selected_version:integer`, `content_hash:string`, and an ActiveStorage attachment for the uploaded file
**And** `db/seeds.rb` creates a hardcoded demo user with a default profile and superposition states for short_form, long_form, and technical content types
**And** `dotenv-rails` is configured with `.env.example` listing `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`, `LANGSMITH_API_KEY`
**And** `rails db:create db:migrate db:seed` completes without errors
**And** `rails server` starts and serves a root page successfully

---

### Story 1.2: Upload Page — Accept & Store Content

As a user,
I want to upload a document (image, PDF, or text file) through a clean upload page,
So that my content is stored and ready for transformation.

**Acceptance Criteria:**

**Given** the demo user navigates to `/upload`
**When** the upload page loads
**Then** a form is displayed with a file input accepting `.txt`, `.pdf`, `.png`, `.jpg`, `.jpeg` file types
**And** the form includes a submit button labeled "Transform My Content"

**Given** the user selects a valid text file and submits the form
**When** the upload completes
**Then** the file is stored via ActiveStorage on the Document record
**And** the text content is extracted and saved to `extracted_text` on the Document
**And** the user is redirected to `/results/:id` where `:id` is the new Document's ID

**Given** the user selects a valid PDF file and submits the form
**When** the upload completes
**Then** the file is stored via ActiveStorage
**And** the document record is created with the file attached
**And** the user is redirected to `/results/:id`

**Given** the user selects a valid image file and submits the form
**When** the upload completes
**Then** the file is stored via ActiveStorage
**And** the document record is created with the file attached
**And** the user is redirected to `/results/:id`

**Given** the user submits the form without selecting a file
**When** validation runs
**Then** an error message is displayed: "Please select a file to upload"
**And** the user remains on the `/upload` page

---

### Story 1.3: Results Page — 4 Transformation Versions Side-by-Side

As a user,
I want to see 4 different transformation versions of my uploaded content displayed as cards,
So that I can compare styles and find the one that works best for me.

**Acceptance Criteria:**

**Given** a Document record exists with an uploaded file at `/results/:id`
**When** the results page loads
**Then** 4 transformation version cards are displayed side-by-side (or in a 2x2 grid on smaller screens)
**And** each card has a title indicating the transformation style (e.g., "Simplified", "Bullet Points", "Plain Language", "Restructured")
**And** each card displays the transformed content for that style
**And** the original content is accessible via a "Show Original" toggle button

**Given** the results page is loaded
**When** the user clicks the "Show Original" toggle on any card
**Then** the card content switches to show the original text
**And** the toggle button label changes to "Show Transformed"
**And** the switch happens instantly on the client side with no server round-trip (NFR4)

**Given** the results page is loaded
**When** the user views the before/after comparison
**Then** the original content and the transformed version are visually distinguishable (different background colors or side-by-side layout)

**Given** the Document has no transformation results yet (AI agent has not processed it)
**When** the results page loads
**Then** placeholder cards are shown with a loading or "processing" state
**And** the page gracefully handles the absence of transformation data

---

### Story 1.4: Pick Best Version — Collapse to Preferred Style

As a user,
I want to pick the transformation version I prefer by clicking a "Pick This Version" button,
So that the system saves my preference and shows me the collapsed (final) result.

**Acceptance Criteria:**

**Given** the user is viewing 4 transformation cards on `/results/:id`
**When** the user clicks the "Pick This Version" button on one of the 4 cards
**Then** the selected version number is saved to `Document.selected_version`
**And** the user's preferred style is saved to `User.profile` (updating the `preferred_style` key)
**And** the user is redirected to `/collapsed/:id`

**Given** the user navigates to `/collapsed/:id`
**When** the page loads
**Then** only the selected transformation version is displayed prominently
**And** the original content is shown below or accessible via toggle for comparison
**And** a label indicates which style was chosen (e.g., "You chose: Bullet Points")
**And** a "Back to All Versions" link returns the user to `/results/:id`
**And** a "Upload New Document" link takes the user to `/upload`

**Given** the user has not yet picked a version
**When** they navigate directly to `/collapsed/:id`
**Then** they are redirected back to `/results/:id`

---

### Story 1.5: Profile Page — Preferences & Document History

As a user,
I want to see my saved reading preference and a history of all my transformed documents,
So that I can review past results and understand my preferred style.

**Acceptance Criteria:**

**Given** the demo user navigates to `/profile`
**When** the profile page loads
**Then** the user's saved preferred style is displayed prominently (e.g., "Your Preferred Style: Bullet Points")
**And** if no style has been chosen yet, a message says "No preference saved yet — upload a document to get started"

**Given** the user has transformed documents in their history
**When** the profile page loads
**Then** a list of all past documents is displayed, ordered by most recent first
**And** each entry shows: file name, upload date, selected style (or "Not yet chosen"), and a link to `/results/:id` or `/collapsed/:id`

**Given** the user has no documents yet
**When** the profile page loads
**Then** an empty state message is displayed: "No documents yet — upload your first one!"
**And** a link to `/upload` is provided

**Given** the user's accessibility profile exists in the database
**When** the profile page loads
**Then** the current profile settings are displayed (sentence length preference, font preference, color overlay, etc.) in a readable format

---

### Story 1.6: UI Polish — WOW Layout & Collapse Animation

As a user,
I want a visually polished, accessible interface with smooth animations,
So that the app feels professional and delightful to use.

**Acceptance Criteria:**

**Given** the user is on any page of the application
**When** the page renders
**Then** the layout uses Tailwind CSS with consistent spacing, typography, and color scheme
**And** a navigation bar is present with links to Upload, Profile, and the Qlarity logo/name
**And** color contrast meets WCAG 2.1 AA minimum (4.5:1 for normal text, 3:1 for large text) (NFR6)
**And** all interactive elements (buttons, links, toggles) are keyboard-navigable via Tab and activated via Enter/Space (NFR7)
**And** no content flashes, auto-playing audio, or unexpected layout shifts occur (NFR10)

**Given** the user is on the `/results/:id` page with 4 cards
**When** the user clicks "Pick This Version" on a card
**Then** the other 3 cards animate out (fade/shrink) and the selected card animates to a prominent centered position before redirecting to `/collapsed/:id`
**And** if CSS animations are not feasible within scope, the redirect happens immediately without animation (graceful degradation)

**Given** the user views the 4-card layout on a desktop screen (>1024px)
**When** the results page renders
**Then** the cards are displayed in a 4-column grid layout

**Given** the user views the 4-card layout on a tablet or mobile screen (<1024px)
**When** the results page renders
**Then** the cards stack into a 2x2 grid or single column layout
**And** all content remains readable and interactive
