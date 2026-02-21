---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish]
inputDocuments:
  - docs/planning-artifacts/product-brief-hackeurope-2026-02-21.md
  - docs/brainstorming/brainstorming-session-2026-02-21.md
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 1
  projectDocs: 0
  projectContext: 0
classification:
  projectType: 'web_app_api_backend'
  domain: 'saas_b2b'
  complexity: 'medium'
  projectContext: 'greenfield'
---

# Product Requirements Document - Qlarity

**Author:** team
**Date:** 2026-02-21

## Executive Summary

Qlarity is an AI-powered reading optimization agent that transforms corporate web content for the 15% of employees with dyslexia. Built on Ruby on Rails with Claude's API and LangSmith tracing, it replaces static, one-size-fits-all accessibility tools with personalized, semantic text transformation driven by a quantum superposition profile model.

The core problem: dyslexic employees navigate Slack, Teams, Jira, and email daily, where dense text creates persistent productivity barriers — missed messages, misread instructions, avoidable errors, and compounding cognitive fatigue. Existing tools (Helperbird, OpenDyslexic, BeeLine Reader) apply identical CSS-level changes to every user. They never rewrite content, never personalize, never adapt to context, and never prove their value.

Qlarity solves this with four capabilities: (1) a conversational onboarding agent that maps each user's specific difficulties — long sentences, jargon, visual crowding, paragraph density — into a structured accessibility profile, (2) a semantic transformation engine that uses Claude to actually rewrite text while preserving meaning, (3) a superposition profile model that holds multiple possible accessibility pathways simultaneously, collapsing to the optimal transformation based on both the user's specific difficulties and the content context, and (4) ElevenLabs text-to-speech that reads transformed content aloud, providing dual-channel accessibility (visual + auditory).

Target: hackathon MVP for the paid.ai Agentic AI track. Must demonstrate an agent that autonomously completes a meaningful task and proves its value through measurable economics.

### What Makes This Special

**Quantum Superposition Profile Model:** Unlike tools that assign one fixed accessibility profile, Qlarity's AI explores a multi-dimensional space of possible adaptations per user. During onboarding, the agent takes user input about their specific struggles and generates multiple co-existing accessibility states — different combinations of sentence simplification, jargon replacement, bullet restructuring, spacing adjustments, and color overlays. These states exist simultaneously until the system observes how the user interacts with specific content types, then resolves to the optimal pathway. The same user collapses to different optimal states for a quick Slack message vs. a dense Jira ticket vs. a long email chain. This is fundamentally impossible with static CSS extensions.

**Semantic Rewriting, Not CSS:** Claude rewrites the actual text — breaking complex sentences, replacing jargon with plain language, restructuring paragraphs into scannable bullet points — while preserving meaning. A 40-word compound sentence becomes three clear statements. This is the capability gap no existing tool addresses.

**Destigmatized by Design:** Qlarity never mentions dyslexia to the user. It's framed as "reading optimization" — no diagnosis required, no HR disclosure, no labels. The onboarding feels like a fun quiz, not a medical intake.

**Built-In Value Proof:** Every transformation is traced via LangSmith — cost per operation, latency, token usage, readability score delta. The agent proves its own ROI: "$0.003 per transformation, 2+ grade level readability improvement, 15+ daily transformations per user."

## Project Classification

- **Project Type:** Web App + API Backend (Rails app serving API endpoints with web demo frontend)
- **Domain:** B2B SaaS (corporate accessibility tool sold to enterprises)
- **Complexity:** Medium (AI agent integration + accessibility standards, no heavy regulatory burden)
- **Project Context:** Greenfield (new hackathon project, no existing codebase)

## Success Criteria

### User Success

**S1. Readability Transformation:** Content is measurably easier to read after Qlarity processes it. Target: 2+ Flesch-Kincaid grade level improvement per transformation, verified by ReadabilityScorer tool on every run.

**S2. Comprehension on First Read:** Users understand transformed content without re-reading. Target: <10% of content requires repeat transformation. Measured via duplicate content hash detection in LangSmith run metadata.

**S3. Content Engagement Recovery:** Users engage with content they previously skipped. Target: transformation utilization of 15+ daily requests per active user, indicating the tool is embedded in real workflow.

**S4. Frictionless Onboarding:** Users complete profile setup without friction or stigma. Target: 90%+ onboarding completion rate in 3-5 conversational turns. Measured via OnboardingAgent trace completion in LangSmith.

**S5. Personalization Accuracy:** The superposition model resolves to transformations that match the user's actual difficulties. Target: users don't need to manually override or reject transformations after the profile stabilizes.

### Business Success

**B1. Hackathon Demo:** End-to-end flow works live — onboard a user, paste corporate content, show transformed output with before/after comparison and value metrics.

**B2. Actual Workplace Transformation:** The demo proves this genuinely transforms how dyslexic employees experience corporate text — not a toy, but a tool that would change someone's workday.

**B3. Agent Economics Visible:** Every transformation shows its cost, latency, and readability improvement via LangSmith — proving the agent's value is measurable and the economics work at scale.

### Technical Success

**T1. Semantic Rewriting Works:** Claude produces meaningful text transformations — shorter sentences, simplified jargon, restructured layouts — that preserve original meaning.

**T2. Superposition Resolution:** The agent resolves different transformation intensities for different content types (short Slack message vs. dense Jira ticket) from the same user profile.

**T3. Full LangSmith Tracing:** Every onboarding conversation and transformation is traced with tagged metadata (user_id, content_type, cost, latency, readability delta).

**T4. Sub-3 Second Transformation:** Content transforms fast enough to feel responsive in a real workflow context.

### Measurable Outcomes

| Outcome | Metric | Target | Source |
|---|---|---|---|
| Readability improvement | Flesch-Kincaid delta | +2 grade levels avg | ReadabilityScorer |
| Onboarding completion | Profiles completed / started | 90%+ | OnboardingAgent traces |
| Daily utilization | Transformations per user/day | 15+ | LangSmith run count |
| Cost efficiency | Claude API cost per transformation | <$0.005 | LangSmith cost tracking |
| Response time | End-to-end transformation latency | <3 seconds | LangSmith latency |
| Comprehension | Repeat transformation rate | <10% | LangSmith content hashing |

## Product Scope

### MVP - Minimum Viable Product

1. **OnboardingAgent** — Conversational AI (Claude + tool_use) builds JSON accessibility profile in 3-5 turns. Maps user-specific difficulties (long sentences, jargon, visual crowding, paragraph density). Generates superposition states for multiple content contexts.
2. **TransformAgent** — Rails service object pipeline: TextSimplifier, SentenceSplitter, ReadabilityScorer. Claude performs semantic rewriting per user profile. Superposition model resolves transformation intensity based on content type.
3. **ElevenLabs TTS** — Text-to-speech reads transformed content aloud. Dual-channel accessibility: users hear simplified text while viewing it. Fallback to browser Web Speech API.
4. **LangSmith Tracing** — Full observability via langsmithrb_rails. Every run tagged with user_id, content_type, cost, latency, readability delta.
5. **Web Demo Page** — Simulated corporate messaging UI. Paste content, transform, listen, toggle original/accessible view. Value metrics displayed per transformation.

### Growth Features (Post-MVP)

- Chrome extension for real-time HTML rewriting across live corporate web apps
- Voice preference selection and reading speed control for TTS
- Implicit profile refinement from reading behavior patterns
- User feedback loop ("I prefer this version") to sharpen superposition resolution
- Multi-user support with authentication

### Vision (Future)

- Multi-neurodiverse platform — ADHD, ESL, cognitive load profiles using same architecture
- Cognitive load adaptation — calendar integration, time-of-day fatigue signals
- Writing assistant mode — coach content creators to write accessibly
- Enterprise deployment — IT admin dashboard, org-wide rollout, anonymized team analytics
- API platform — corporate apps integrate Qlarity as invisible accessibility infrastructure

## User Journeys

### Journey 1: Sam — First-Time Onboarding & Transformation (Happy Path)

**Opening Scene:** Sam is a project manager at a 500-person tech company. It's Monday morning and their Slack is flooded with weekend messages — dense paragraphs from engineering, a long thread about a deadline change, three @mentions buried in walls of text. Sam has dyslexia but has never told anyone at work. They spend the first 30 minutes of every day just trying to parse what happened while they were away, re-reading messages twice, sometimes three times. Today, Sam notices Qlarity — installed company-wide as a "reading optimization" tool. No mention of dyslexia anywhere.

**Rising Action:** Sam clicks "Optimize my reading experience" and meets the onboarding agent. It doesn't ask clinical questions. Instead, it shows two versions of the same paragraph: "Which one is easier to read?" Sam taps the shorter-sentence version. Another pair appears — one with bullet points, one without. Sam picks bullets. Three more quick rounds: jargon vs. plain language, tight spacing vs. open spacing, color overlay options. It feels like a Buzzfeed quiz, not a medical assessment. In under 2 minutes, the agent says: "Got it — I've built your reading profile."

**Climax:** Sam returns to Slack. They paste a dense 200-word engineering update into Qlarity. The agent detects it's a technical thread (superposition collapses to "dense technical content" state) and returns: the same information restructured into 5 clear bullet points, jargon replaced with plain language, key action items bolded. Sam reads it once and understands everything. No re-reading. No asking a colleague to explain. For the first time, the information just lands.

**Resolution:** By end of week, Sam has transformed 80+ messages. They're reading full Slack threads they used to skip. They caught a deadline change in a Jira ticket they would have missed. They leave work at 5pm feeling less mentally drained than usual. The LangSmith dashboard shows: 84 transformations, average +2.3 grade level improvement, $0.25 total cost. Sam thinks: "This is how text should have always looked for me."

**Capabilities Revealed:** Onboarding flow, profile creation, content pasting, semantic transformation, context detection, before/after display, value metrics.

---

### Journey 2: Sam — Superposition Resolution Across Contexts (Edge Case)

**Opening Scene:** Sam has been using Qlarity for a few days. Their profile is set. Now they encounter different content types back to back: a quick 2-sentence Slack DM from a colleague, then a 500-word Jira epic with acceptance criteria and technical specs.

**Rising Action:** Sam pastes the Slack DM: "Hey, can you review the PR for the login fix? Should be quick." The agent detects short-form casual messaging — the superposition collapses to a minimal transformation state. It returns the message with only light adjustments: slightly increased spacing, one jargon term clarified. The message is essentially the same because it didn't need heavy transformation.

**Climax:** Sam then pastes the Jira epic. The agent detects dense technical documentation — the superposition collapses to maximum transformation. Complex sentences are broken apart. Technical jargon gets inline plain-language explanations. Acceptance criteria are reformatted into a clean numbered list. A 500-word wall of text becomes a structured, scannable document.

**Resolution:** Sam sees that Qlarity doesn't over-process simple content or under-process complex content. The same profile produces different outputs depending on what the content actually demands. Sam trusts the tool more because it's not blindly applying the same filter to everything.

**Capabilities Revealed:** Superposition model resolution, content type detection, variable transformation intensity, appropriate restraint on simple content.

---

### Journey 3: Sam — Transformation Misses the Mark (Error Recovery)

**Opening Scene:** Sam pastes a message that contains a company-specific acronym: "The TPS report for Q3 OKRs needs PMO sign-off before the ELT review." The agent simplifies jargon — but replaces "TPS" with a generic expansion that's wrong for Sam's company.

**Rising Action:** Sam sees the incorrect expansion and feels a moment of doubt. The transformed version says "Third Party Services report" but at Sam's company TPS means "Technical Project Status." The meaning has shifted.

**Climax:** Sam clicks the toggle to see the original side-by-side with the transformation. They can instantly identify what changed and what's wrong. The original is always one click away — Qlarity never hides or destroys the source content.

**Resolution:** Sam's trust isn't broken because the original is always accessible. They use the correctly transformed parts (simplified sentence structure, bullet formatting) and mentally note the acronym issue. In a future version, Sam would flag this via a feedback mechanism to train the agent on company-specific terminology. For MVP, the toggle/original view is the safety net.

**Capabilities Revealed:** Original/transformed toggle, error transparency, graceful degradation, trust preservation through source access.

---

### Journey 4: Hackathon Demo Presenter

**Opening Scene:** It's demo day at the hackathon. The team has 3-5 minutes to show Qlarity to judges from the paid.ai Agentic AI track. The judges care about: does the agent work, does it complete a meaningful task, and can you prove its value?

**Rising Action:** The presenter opens Qlarity's web demo. They run the onboarding live — 5 quick taps showing the gamified profile builder. The judges see a profile being constructed in real-time. Then the presenter pastes a real corporate message — dense, jargon-heavy, poorly formatted.

**Climax:** One click. The content transforms. The presenter toggles between original and accessible view. The difference is visually dramatic. Then they show the value metrics: "This transformation cost $0.003, improved readability by 2.4 grade levels, and took 1.8 seconds. Across a workday of 15+ transformations, that's $0.05 to unlock productivity for someone who was struggling with every message."

**Resolution:** The presenter shows the LangSmith trace — full observability into every agent decision. Cost per run, token usage, latency, readability delta. They close with: "15% of your workforce has dyslexia. Qlarity transforms their entire workday for less than a dollar a month. And LangSmith proves every cent of value."

**Capabilities Revealed:** End-to-end demo flow, visual impact of transformation, value metrics display, LangSmith integration, pitch narrative.

### Journey Requirements Summary

| Journey | Key Capabilities Required |
|---|---|
| Sam — Happy Path | Onboarding agent, profile JSON, semantic transformation, context detection, before/after view, value metrics |
| Sam — Superposition | Content type detection, variable transformation intensity, superposition resolution logic |
| Sam — Error Recovery | Original/transformed toggle, source preservation, graceful degradation |
| Demo Presenter | End-to-end flow, visual demo page, LangSmith traces, value dashboard display |

**Cross-cutting requirements revealed:**
- Original content must always be accessible (never destructive)
- Transformation intensity must vary by content type (superposition)
- Value metrics must be visible per transformation
- Onboarding must be completable in under 2 minutes
- LangSmith traces must be queryable for demo dashboard

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. Quantum Superposition Profile Model**
No existing accessibility tool maintains multiple co-existing accessibility states per user. Current tools assign one static profile. Qlarity generates multiple possible transformation pathways from onboarding input, holds them in superposition, and collapses to the optimal state based on content context. This is a novel application of quantum-inspired computing principles to personalization — the system explores a multi-dimensional space of accommodations rather than picking one preset.

**2. Semantic AI Rewriting for Accessibility**
Every existing dyslexia tool operates at the CSS level — font swaps, color overlays, line spacing. None use AI to rewrite the actual text. Qlarity uses Claude to perform semantic transformation: breaking complex sentences, replacing jargon, restructuring paragraphs into scannable formats — while preserving meaning. This is a new category of accessibility tool that didn't exist before LLMs made it possible.

**3. Self-Proving AI Agent (Built-in Economics)**
Most AI agents cannot demonstrate their own value. Qlarity traces every transformation via LangSmith — cost, latency, token usage, readability delta — creating a real-time value proof layer. The agent literally proves its ROI on every operation. This directly addresses the paid.ai track thesis: "95% of AI pilots fail because organizations can't track agent impact."

**4. Destigmatized Accessibility by Design**
Qlarity never mentions dyslexia to the user. The entire product is framed as "reading optimization." The onboarding is gamified, not clinical. No diagnosis required, no HR disclosure, no labels. This is a design innovation that removes every adoption barrier — the tool is accessible to people who would never use a "dyslexia tool."

### Market Context & Competitive Landscape

- **Helperbird, OpenDyslexic, BeeLine Reader** — CSS-only, no personalization, no AI, no value proof
- **Grammarly** — AI-powered writing assistant but focused on writing, not reading accessibility
- **No direct competitor** combines AI semantic rewriting + personalized profiles + value tracing for accessibility
- **Timing:** LLM capabilities (Claude) make semantic rewriting possible now — this product category couldn't exist 2 years ago

### Validation Approach

- **Hackathon MVP validates core hypothesis:** Does AI semantic rewriting measurably improve readability for dyslexic users?
- **Readability score delta** (Flesch-Kincaid before/after) provides objective validation on every transformation
- **Superposition validation:** Demo shows same user profile producing different transformation intensities for different content types
- **Value proof validation:** LangSmith traces demonstrate cost/benefit per transformation

### Risk Mitigation

See **Project Scoping & Phased Development → Risk Mitigation Strategy** for comprehensive technical, market, and resource risk analysis.

## Web App + API Backend Specific Requirements

### Project-Type Overview

Qlarity is a Ruby on Rails web application serving both a web demo frontend and a JSON API backend. The Rails app hosts the OnboardingAgent and TransformAgent as service objects, exposes RESTful API endpoints for content transformation and profile management, and renders a Hotwire-powered (Turbo + Stimulus) frontend for the hackathon demo. PostgreSQL stores user profiles with JSON columns for superposition states. Claude API provides the AI backbone; LangSmith provides full observability.

### API Endpoints

| Endpoint | Method | Description | Request | Response |
|---|---|---|---|---|
| `/api/onboarding` | POST | Process onboarding conversation turn | `{ user_id, message, conversation_history[] }` | `{ reply, profile_progress, complete: bool, profile?: {} }` |
| `/api/transform` | POST | Transform content per user profile | `{ user_id, content, content_type?: string }` | `{ original, transformed, metrics: { readability_before, readability_after, delta, cost, latency, tokens } }` |
| `/api/profile` | GET | Retrieve user's accessibility profile | `?user_id=` | `{ profile: { ...schema }, superposition_states: {} }` |
| `/api/metrics` | GET | Query transformation value metrics | `?user_id=&period=` | `{ total_transformations, avg_readability_delta, total_cost, avg_latency }` |

### Authentication Model

**MVP (Hackathon):** No authentication. Single demo user with hardcoded `user_id`. Profile stored in session/database without auth layer.

**Post-MVP:** Token-based API authentication for multi-user support. Enterprise SSO integration planned for future deployment.

### Data Schemas

**UserProfile:**

```json
{
  "user_id": "string",
  "sentence_length": "short | medium",
  "font_preference": "opendyslexic | default | sans-serif",
  "color_overlay": "#hex | none",
  "simplify_jargon": true,
  "bullet_points": true,
  "max_paragraph_length": 3,
  "line_spacing": "relaxed | normal",
  "highlight_keywords": true,
  "superposition_states": {
    "short_form": { "intensity": "minimal", "transformations": ["spacing"] },
    "long_form": { "intensity": "moderate", "transformations": ["simplify", "bullets", "spacing"] },
    "technical": { "intensity": "maximum", "transformations": ["simplify", "jargon", "bullets", "restructure"] }
  }
}
```

**TransformResponse:**

```json
{
  "original": "string (preserved input)",
  "transformed": "string (rewritten output)",
  "content_type_detected": "short_form | long_form | technical",
  "superposition_state_used": "string",
  "metrics": {
    "readability_before": 12.3,
    "readability_after": 8.1,
    "readability_delta": -4.2,
    "flesch_kincaid_before": 14.2,
    "flesch_kincaid_after": 9.8,
    "cost_usd": 0.003,
    "latency_ms": 1800,
    "tokens_used": 450
  },
  "tts": {
    "audio_url": "string (streaming endpoint or base64)",
    "voice_id": "string",
    "tts_cost_usd": 0.001,
    "tts_latency_ms": 800
  }
}
```

### Frontend Architecture

**Technology:** Rails 7+ views with Hotwire (Turbo Frames + Stimulus controllers)

- **Onboarding View:** Turbo Frame-driven conversational UI. Each onboarding turn submits via Turbo, updates the conversation frame without full page reload. Stimulus controller manages conversation state and progress indicator.
- **Transform View:** Text input area + transform button. Turbo Frame swaps in transformed content. Toggle controller (Stimulus) switches between original and transformed views. Metrics panel updates with each transformation.
- **No SPA framework needed** — Hotwire provides sufficient interactivity for the demo.

### Multi-Tenancy Model

**MVP:** Single-tenant. One demo user, no tenant isolation needed.

**Post-MVP:** Organization-based tenancy. Each enterprise customer gets isolated data with shared application infrastructure.

### Permission Model

**MVP:** No permissions. All endpoints are open for demo purposes.

**Post-MVP:** Role-based — Admin (manage org settings, view aggregate metrics), User (own profile, transform content).

### Integration Architecture

| Integration | Purpose | Method |
|---|---|---|
| Claude API (Anthropic) | Semantic rewriting + onboarding conversation | REST API via `anthropic` Ruby gem, `tool_use` for structured extraction |
| ElevenLabs TTS API | Text-to-speech for transformed content | REST API, stream audio to browser |
| LangSmith | Tracing, cost tracking, observability | `langsmithrb_rails` gem or REST API / OpenTelemetry |
| PostgreSQL | User profiles, transformation history | ActiveRecord with JSON columns |

### Error Handling

| Error Scenario | Handling Strategy |
|---|---|
| Claude API timeout (>5s) | Return original content with "transformation unavailable" message. Never block the user. |
| Claude API rate limit | Queue and retry with exponential backoff. Show loading state. |
| Invalid content input | Validate content length (max 5000 chars for MVP). Return clear error message. |
| Profile not found | Redirect to onboarding flow. |
| LangSmith trace failure | Log locally, don't block transformation. Tracing is non-critical path. |
| ElevenLabs TTS failure | Fallback to browser native Web Speech API. TTS is enhancement, not critical path. |

### Performance Targets

| Metric | Target | Rationale |
|---|---|---|
| Transformation latency | <3 seconds end-to-end | Must feel responsive in real workflow context |
| Onboarding turn latency | <2 seconds per turn | Conversational flow can't have long pauses |
| Content size limit | 5000 characters (MVP) | Keeps Claude API costs predictable, covers most corporate messages |
| Concurrent users | 1 (MVP) | Hackathon demo, single presenter |

### Accessibility Level

Qlarity's own UI must meet WCAG 2.1 AA baseline — it would be ironic for an accessibility tool to have an inaccessible interface. Key considerations: sufficient color contrast, keyboard navigability, screen reader compatibility for the demo page.

### Implementation Considerations

- **Service Object Pattern:** OnboardingAgent and TransformAgent are plain Ruby service objects, not framework-coupled. This keeps logic testable and portable.
- **Claude API via tool_use:** Onboarding agent uses Claude's `tool_use` to simultaneously conduct conversation AND extract structured profile data — no separate parsing step needed.
- **Superposition Resolution:** Content type detection happens before transformation. A lightweight classifier (word count, sentence complexity, jargon density) determines which superposition state to collapse to before calling Claude for the actual rewrite.
- **LangSmith Tagging:** Every run tagged with `{ user_id, content_type, run_type: "onboarding" | "transform" }` for queryable dashboards.
- **Database:** PostgreSQL with `jsonb` columns for profile and superposition states. No schema migrations needed when profile schema evolves.
- **ElevenLabs TTS:** Transformed text is sent to ElevenLabs API after Claude rewriting completes. Audio streamed to browser via HTML5 audio element. Fallback to Web Speech API if ElevenLabs unavailable.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-Solving MVP — prove the core hypothesis that AI semantic rewriting + audio playback measurably transforms corporate text for dyslexic employees, with visible cost/value economics.

**Resource Requirements:** Small team (1-3 developers), single hackathon sprint. Rails full-stack developers with Claude API and ElevenLabs API experience.

**Guiding Principle:** Every feature must serve the 3-5 minute demo: onboard → transform → show before/after → listen to transformed text → show value metrics. If it doesn't appear in the demo, it's not MVP.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- Journey 1 (Sam — Happy Path): Full support — onboard, paste, transform, listen, view
- Journey 2 (Sam — Superposition): Full support — different content types resolve differently
- Journey 3 (Sam — Error Recovery): Partial support — original/transformed toggle only (no feedback mechanism)
- Journey 4 (Demo Presenter): Full support — end-to-end demo flow with TTS and value metrics

**Must-Have Capabilities:**

| # | Capability | Justification |
|---|---|---|
| M1 | OnboardingAgent — 3-5 turn conversational profile builder | Without personalization, this is just another generic tool |
| M2 | TransformAgent — Claude semantic rewriting pipeline | This IS the product. No transformation = no product |
| M3 | Superposition resolution — 3 content type states (short_form, long_form, technical) | Core differentiator. Proves context-aware personalization |
| M4 | ReadabilityScorer — Flesch-Kincaid before/after on every transformation | Required for value proof and success metric S1 |
| M5 | Original/transformed toggle view | Safety net for trust (Journey 3). Non-negotiable |
| M6 | Value metrics display per transformation (cost, latency, readability delta, TTS cost) | Required for paid.ai track — must prove agent economics |
| M7 | LangSmith tracing on every run | Required for observability proof at demo |
| M8 | Web demo page — paste content, transform, listen, view results | The demo surface. Without it, nothing is showable |
| M9 | ElevenLabs TTS — Read transformed content aloud | Dual-channel accessibility (visual + auditory). Hearing simplified text while reading it dramatically improves comprehension for dyslexic users. High demo impact. |

**Explicitly Cut from MVP:**
- No authentication (hardcoded demo user)
- No Chrome extension
- No real Slack/Teams/Jira integration (paste-and-transform only)
- No user feedback mechanism (future)
- No implicit profile refinement
- No multi-user support
- No admin dashboard
- Content size limit: 5000 characters
- No voice preference selection (single default voice for MVP)

### Post-MVP Features

**Phase 2 (Growth):**
- User authentication and multi-user support
- Chrome extension for real-time HTML rewriting in live corporate apps
- Voice preference selection (ElevenLabs voice library)
- Reading speed control for TTS playback
- User feedback loop ("I prefer this version") to sharpen superposition resolution
- Implicit profile refinement from reading behavior patterns
- Company-specific terminology training
- Extended content size support

**Phase 3 (Expansion):**
- Multi-neurodiverse platform — ADHD, ESL, cognitive load profiles
- Cognitive load adaptation — calendar integration, time-of-day fatigue signals
- Writing assistant mode — coach content creators to write accessibly
- Enterprise deployment — IT admin dashboard, org-wide rollout, anonymized team analytics
- API platform — corporate apps integrate Qlarity as invisible infrastructure
- Custom voice cloning per organization (ElevenLabs professional voices)

### Risk Mitigation Strategy

**Technical Risks:**

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Claude semantic rewriting distorts meaning | Medium | High | Original always preserved, one-click toggle. Start with conservative prompts, iterate. |
| Superposition adds complexity beyond hackathon scope | Medium | Medium | Limit to 3 hardcoded content type states. Simple word-count/complexity classifier. |
| LangSmith Ruby integration issues | Low | Medium | Fallback to REST API or OpenTelemetry if gem has issues. |
| Claude API latency exceeds 3s target | Low | Medium | Hackathon uses paste-and-transform (not real-time). Loading state acceptable. |
| ElevenLabs TTS latency or rate limits | Low | Medium | Stream audio (don't wait for full generation). Fallback: browser native Web Speech API if ElevenLabs unavailable. |
| Combined API costs (Claude + ElevenLabs) exceed budget | Low | Low | Both have generous free tiers. Demo volume is tiny. Track per-transformation cost in metrics. |

**Market Risks:**

| Risk | Mitigation |
|---|---|
| Judges don't understand the problem | Lead demo with the "15% of workforce" stat and Sam's daily pain story |
| "Just use Grammarly" objection | Show that Grammarly helps writers, Qlarity helps readers — different problem entirely |
| Superposition concept seems over-engineered | Demo it live — same content, two different types, visibly different outputs |
| "Why not just use browser TTS?" | ElevenLabs reads the *transformed* text with natural voice quality — browser TTS reads the original dense text robotically |

**Resource Risks:**

| Risk | Mitigation |
|---|---|
| Not enough time to build everything | M1-M4 are the critical path. M5-M8 are simpler UI work. M9 (TTS) is a single API call + audio player. Build agents first, demo page second, TTS last. |
| Team member unavailable | Service object pattern means components are independent. Any developer can pick up any piece. |
| Absolute minimum viable demo | OnboardingAgent + TransformAgent + one paste-and-transform page. TTS and metrics display are additive — skip if truly out of time. |

## Functional Requirements

### Profile Onboarding

- **FR1:** User can initiate an onboarding experience framed as "reading optimization" without any reference to dyslexia or medical conditions
- **FR2:** User can complete a conversational onboarding flow in 3-5 turns by choosing between paired content samples (e.g., "Which version is easier to read?")
- **FR3:** System can build a structured accessibility profile from the user's onboarding choices, capturing preferences for sentence length, font, color overlay, jargon simplification, bullet restructuring, paragraph length, line spacing, and keyword highlighting
- **FR4:** System can generate multiple superposition states (short_form, long_form, technical) from a single onboarding session, each with appropriate transformation intensity and transformation types

### Content Transformation

- **FR5:** User can submit text content (up to 5000 characters) for transformation
- **FR6:** System can detect the content type of submitted text (short_form, long_form, or technical) based on content characteristics
- **FR7:** System can resolve the appropriate superposition state based on the detected content type and the user's profile
- **FR8:** System can perform semantic rewriting of text — breaking complex sentences, replacing jargon with plain language, and restructuring paragraphs into scannable formats — while preserving the original meaning
- **FR9:** System can apply variable transformation intensity based on the resolved superposition state (minimal for short_form, moderate for long_form, maximum for technical)
- **FR10:** System can preserve the original content alongside every transformation, never destroying or replacing the source

### Text-to-Speech

- **FR11:** User can listen to the transformed content read aloud via ElevenLabs text-to-speech
- **FR12:** User can control audio playback (play, pause, stop) for transformed content
- **FR13:** System can fall back to browser native Web Speech API if ElevenLabs is unavailable

### Readability Analysis

- **FR14:** System can calculate Flesch-Kincaid readability scores for content before and after transformation
- **FR15:** System can compute the readability delta (grade level improvement) per transformation
- **FR16:** System can detect duplicate content submissions via content hashing to measure re-read rates

### Content Presentation

- **FR17:** User can view transformed content in a corporate messaging-style interface
- **FR18:** User can toggle between original and transformed views of the same content with one click
- **FR19:** User can view before/after comparison of content to see what changed
- **FR20:** System can apply visual accessibility preferences from the user's profile (font, color overlay, line spacing, keyword highlighting) to the transformed view

### Value Metrics & Observability

- **FR21:** User can view per-transformation metrics including readability score delta, cost, latency, and token usage
- **FR22:** User can view aggregate metrics across all their transformations (total count, average readability delta, total cost, average latency)
- **FR23:** System can trace every onboarding conversation and transformation run via LangSmith with tagged metadata (user_id, content_type, run_type, cost, latency, readability delta)
- **FR24:** System can track ElevenLabs TTS cost per transformation alongside Claude API cost
- **FR25:** User can view a value dashboard summarizing the agent's economic impact

### Profile Management

- **FR26:** System can store and retrieve a user's accessibility profile including all superposition states
- **FR27:** User can view their current accessibility profile
- **FR28:** System can use a stored profile for all subsequent transformations without requiring re-onboarding

## Non-Functional Requirements

### Performance

- **NFR1:** Content transformation completes end-to-end in under 3 seconds for content up to 5000 characters
- **NFR2:** Onboarding agent responds to each conversational turn in under 2 seconds
- **NFR3:** ElevenLabs TTS audio begins streaming within 1.5 seconds of user pressing play (not waiting for full generation)
- **NFR4:** Original/transformed toggle switches views instantly (client-side, no server round-trip)
- **NFR5:** Readability scoring adds no more than 200ms to the transformation pipeline (computed locally, not via API)

### Accessibility

- **NFR6:** Qlarity's own UI meets WCAG 2.1 AA compliance — minimum 4.5:1 color contrast ratio for normal text, 3:1 for large text
- **NFR7:** All interactive elements are keyboard-navigable (tab order, enter/space activation, escape to close)
- **NFR8:** Audio playback controls are accessible via keyboard and screen reader
- **NFR9:** Transformed content view respects user's profile preferences (font, color overlay, spacing) consistently across page loads
- **NFR10:** No content flashes, auto-playing audio, or unexpected layout shifts that could disorient users

### Integration Reliability

- **NFR11:** Claude API failures return the original untransformed content with a clear status message — never a blank screen or error page
- **NFR12:** ElevenLabs API failures fall back to browser native Web Speech API transparently, with no user action required
- **NFR13:** LangSmith tracing failures are silent — they never block or slow down the user-facing transformation pipeline
- **NFR14:** All external API calls implement timeouts (Claude: 5s, ElevenLabs: 3s, LangSmith: 2s) to prevent hung requests
- **NFR15:** API cost tracking remains accurate even when individual traces fail to record (local cost calculation as backup)
