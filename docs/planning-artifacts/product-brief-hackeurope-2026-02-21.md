---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - docs/brainstorming/brainstorming-session-2026-02-21.md
date: 2026-02-21
author: team
---

# Product Brief: hackeurope

## Executive Summary

Qlarity is an AI-powered reading optimization agent that personalizes how corporate web content is displayed for employees with dyslexia. Built on Ruby on Rails with Claude's API and full LangSmith tracing, Qlarity transforms content across workplace tools — rewriting sentences, simplifying jargon, and restructuring layouts — tailored to each individual's specific needs through an AI-driven onboarding process. Using a superposition profile model, Qlarity maintains multiple accessibility states per user that resolve dynamically based on context — because reading Slack messages, parsing Jira tickets, and scanning email require different accommodations. Unlike static accessibility tools that apply the same adjustments to everyone, Qlarity learns what works for each user in each context and proves its value with measurable cost and productivity data on every transformation.

---

## Core Vision

### Problem Statement

15% of the corporate workforce has dyslexia. These employees spend their days navigating web-based tools — Slack, Teams, Jira, Confluence, email — where dense, unformatted text creates a persistent barrier to productivity. They miss messages, misread instructions, make avoidable errors, and spend significantly more cognitive effort on tasks their peers handle effortlessly. This costs organizations real money in errors, rework, and lost productivity from a substantial portion of their workforce.

### Problem Impact

- **Financial:** Errors caused by misread communications lead to rework, missed deadlines, and costly mistakes across the organization
- **Productivity:** 15% of employees operate below their potential on every text-heavy task, every day
- **Retention & Inclusion:** Dyslexic employees face invisible friction that compounds into disengagement and attrition
- **Scale:** In a 1,000-person company, ~150 employees are affected — most without disclosure or accommodation

### Why Existing Solutions Fall Short

Current tools (Helperbird, OpenDyslexic, BeeLine Reader) apply static, universal adjustments — the same font swap, color overlay, or line spacing for every user. They fail because:

- **No personalization:** Dyslexia manifests differently in every person. A single "dyslexia mode" helps some and does nothing for others
- **No context awareness:** The same profile is applied whether you're scanning a quick Slack message or reading a dense technical document — but these require fundamentally different accommodations
- **CSS-only changes:** They modify appearance but never touch the actual content. A complex 40-word sentence stays a complex 40-word sentence
- **No value proof:** Organizations can't measure whether these tools actually help, making budget justification impossible
- **Stigma:** Most require users to self-identify as dyslexic, which many employees avoid in corporate settings

### Proposed Solution

Qlarity is an AI agent built in Ruby on Rails that:

1. **Personalizes through onboarding:** A conversational AI agent (powered by Claude) conducts a short, gamified onboarding to build each user's unique accessibility profile — stored as a structured JSON schema covering sentence length preferences, font needs, color overlays, jargon simplification, bullet point restructuring, and more
2. **Superposition profile model:** Each user doesn't have one profile — they have multiple co-existing accessibility states that resolve dynamically based on context. Reading a quick Slack thread may need minimal adjustment (light formatting, shorter sentences), while parsing a dense Jira ticket triggers full transformation (simplified vocabulary, bullet restructuring, progressive disclosure). The agent detects the content context and collapses to the right profile automatically
3. **Rewrites content semantically:** Unlike CSS-only tools, Qlarity uses Claude to actually transform text — breaking complex sentences, replacing jargon with plain language, restructuring paragraphs into scannable formats — while preserving meaning
4. **Works across corporate web apps:** Transforms output from Slack, Teams, Jira, email, and other web-based tools — with context-aware profile resolution per application
5. **Proves its value:** Full LangSmith tracing on every transformation tracks cost per operation, time saved, readability improvements, and engagement metrics — giving organizations concrete ROI data

### Key Differentiators

| Differentiator | Qlarity | Existing Tools |
|---|---|---|
| **Personalization** | AI-built individual profile per user | Same settings for everyone |
| **Context awareness** | Superposition model — multiple profiles resolve per context | Single static profile applied everywhere |
| **Transformation depth** | Semantic rewriting (sentence structure, vocabulary, layout) | CSS-only (font, color, spacing) |
| **Value proof** | LangSmith-traced cost/savings per transformation | No measurable outcomes |
| **User framing** | "Reading optimization" — no diagnosis needed | "Dyslexia tool" — requires self-disclosure |
| **Architecture** | AI agent with modular tool pipeline | Static browser extension |

## Target Users

### Primary Users

**Persona: Sam — Corporate Employee with Dyslexia**

**Context:** Sam is a mid-career professional at a large enterprise. Their specific role doesn't matter — Sam could be a developer parsing pull request reviews, a project manager reading Jira tickets, a sales rep scanning CRM notes, or an HR coordinator reviewing policy documents. What matters is that Sam spends most of their workday reading text across multiple corporate web apps.

**Background:**
- Has dyslexia but has never disclosed it at work — and doesn't want to
- Has tried browser extensions like OpenDyslexic and Helperbird, found them too generic to actually help
- Developed personal workarounds: re-reading messages multiple times, asking colleagues to clarify, avoiding long documents when possible, copying text into personal tools to reformat it

**Daily Pain:**
- Slack threads with dense, unformatted paragraphs take 3-4x longer to process than for peers
- Complex Jira tickets with technical jargon cause misunderstandings that lead to errors
- Long email chains get skimmed or skipped entirely — important details are missed
- The cognitive load of processing raw corporate text compounds throughout the day, leading to fatigue and reduced output by afternoon

**What Sam Wants:**
- Text that just *looks right* without having to configure anything or tell anyone about their dyslexia
- Different adjustments for different contexts — quick Slack messages need light touch, dense documentation needs full rewriting
- To feel like they're working on a level playing field with their colleagues

**Success Looks Like:**
- Sam installs Qlarity, completes a quick onboarding that feels like a fun quiz (not a medical intake), and immediately sees corporate content transformed to match how their brain processes text best. Within a week, they're reading full Slack threads they used to skip, catching details in Jira tickets they used to miss, and leaving work with less cognitive fatigue.

### Secondary Users

N/A for hackathon scope. Future considerations:
- **IT Admin / Buyer:** Deploys Qlarity org-wide, views aggregate value dashboard
- **Team Manager:** Sees anonymized team productivity metrics
- **Content Creators:** Receive guidance on writing more accessibly (reverse mode)

### User Journey

**1. Discovery:** Sam finds Qlarity through company-wide deployment (IT installs it) or discovers it independently as a "reading optimization" tool — no dyslexia label required

**2. Onboarding:** A short, conversational AI agent conducts 3-5 turns of gamified micro-tests: "Which version is easier to read? Tap to choose!" — building Sam's unique accessibility profile without asking clinical questions. The superposition profile model creates multiple context states from this single onboarding

**3. Core Usage:** Qlarity runs in the background. When Sam opens Slack, the agent detects the context (short-form messaging) and applies light adjustments. When Sam opens a dense Jira ticket, the agent collapses to a deeper transformation profile — rewriting sentences, simplifying jargon, restructuring into bullet points. Sam can toggle between original and transformed views with one click

**4. Aha Moment:** The first time a 200-word Jira ticket with technical jargon gets rewritten into 5 clear bullet points that Sam understands on first read — no re-reading, no asking a colleague to explain. Sam thinks: "This is how text should have always looked for me"

**5. Long-term:** Qlarity becomes invisible infrastructure. Sam forgets it's there — corporate text just *works*. The profile refines silently over time through implicit feedback. Sam's error rate drops, their response speed increases, and they engage with content they previously avoided

## Success Metrics

### User Success Metrics (Primary)

**1. Readability Score Improvement**
- Measure: Flesch-Kincaid readability score of content before and after transformation
- Target: Average improvement of 2+ grade levels per transformation
- How: ReadabilityScorer tool calculates pre/post scores on every transformation, traced via LangSmith

**2. Content Engagement Recovery**
- Measure: Percentage of content the user engages with after Qlarity vs. before
- Target: Users engage with 90%+ of transformed content vs. estimated 60% baseline
- How: Track transformation requests per session — more requests = more content being consumed rather than skipped

**3. Re-read Reduction**
- Measure: Number of times a user requests the same content transformed (proxy for comprehension on first read)
- Target: <10% of content requires re-transformation or re-reading
- How: Track repeat transformation requests for identical content via LangSmith run metadata

**4. Transformation Utilization**
- Measure: Daily transformations per active user
- Target: Consistent daily usage indicating the tool is embedded in workflow
- How: LangSmith run counts per user_id per day

**5. Onboarding Completion Rate**
- Measure: Percentage of users who complete the full onboarding profile build
- Target: 90%+ completion (validates that onboarding is quick and non-stigmatizing)
- How: Track onboarding agent conversation turns — completed = profile JSON saved

### Business Objectives

- **Hackathon Demo:** Prove measurable readability improvement on real corporate content with visible cost-per-transformation data
- **Post-Hackathon:** Demonstrate ROI to enterprise buyers — "$X/month per employee saves $Y in error reduction and productivity gains"

### Key Performance Indicators

| KPI | Measurement | Target | Data Source |
|---|---|---|---|
| Readability improvement | Flesch-Kincaid delta per transformation | +2 grade levels avg | ReadabilityScorer tool |
| Content engagement | Transformations per user per day | 15+ daily | LangSmith run count |
| Onboarding completion | Profile JSON saved / onboarding started | 90%+ | OnboardingAgent traces |
| Cost per transformation | Claude API token cost per run | <$0.005 avg | LangSmith cost tracking |
| User retention signal | Active days per week per user | 4+ days/week | LangSmith unique user runs |

## MVP Scope

### Core Features

**1. OnboardingAgent**
- Conversational AI agent powered by Claude API with tool_use
- 3-5 turn gamified onboarding flow ("Which version is easier to read?")
- Builds structured JSON accessibility profile per user
- Framed as "reading optimization" — no dyslexia disclosure required
- Profile schema: `{ sentence_length, font_preference, color_overlay, simplify_jargon, bullet_points, max_paragraph_length, line_spacing, highlight_keywords }`

**2. TransformAgent**
- Rails service object orchestrating modular tool pipeline
- Tool functions: `TextSimplifier`, `SentenceSplitter`, `ReadabilityScorer`
- Claude API performs semantic rewriting based on user profile
- Receives HTML content → extracts text → transforms per profile → returns accessible HTML
- Superposition profile model: multiple context states resolve based on content type (short-form messaging vs. dense documentation)

**3. LangSmith Tracing**
- Full tracing on every onboarding conversation and transformation via `langsmithrb_rails` gem (or REST API / OpenTelemetry)
- Tagged metadata per run: user_id, content_type, transformation_count
- Cost, latency, and token usage tracked automatically
- Queryable for value dashboard data

**4. Web Demo Page**
- Simple page simulating corporate messaging UI (Slack/Teams-style)
- Paste or load sample corporate messages
- "Transform" button calls TransformAgent API
- Toggle view: original vs. accessible version side-by-side
- Value metrics displayed: readability score delta, cost per transformation, time estimate saved

### Out of Scope for MVP

- Chrome extension / browser extension (web demo only)
- Real Slack/Teams/Jira integration
- ADHD, ESL, or other neurodiverse profiles
- Cognitive load monitoring / time-of-day adaptation
- Writing assistant (reverse mode for content creators)
- Team dashboard / admin views
- User authentication / multi-tenancy (single demo user for hackathon)
- Implicit feedback loop / silent profile refinement

### MVP Success Criteria

- OnboardingAgent completes profile build in 3-5 conversational turns
- TransformAgent achieves 2+ grade level readability improvement on sample content
- Superposition model resolves different transformation intensity for short-form vs. long-form content
- LangSmith traces show full cost/latency data for every run
- Demo page clearly shows before/after transformation with value metrics
- End-to-end flow works: onboard → profile saved → paste content → transformed output displayed

### Future Vision

- **Chrome extension** with real-time HTML rewriting across corporate web apps
- **Multi-neurodiverse platform** — ADHD, ESL, cognitive load profiles using same architecture
- **Cognitive load adaptation** — calendar integration, time-of-day, fatigue signals
- **Writing assistant mode** — coach content creators to write accessibly
- **Enterprise deployment** — IT admin dashboard, org-wide rollout, anonymized team analytics
- **Implicit learning** — silent profile refinement from reading behavior patterns
- **API platform** — corporate apps integrate Qlarity directly as invisible infrastructure
