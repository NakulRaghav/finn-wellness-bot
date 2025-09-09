# Finn — v0 AI Wellness Bot

Finn is a small, privacy-minded, retrieval-augmented (RAG) wellness assistant. It answers basic health and wellness questions using a curated knowledge base and the user’s app data, handles out-of-scope queries gracefully, and includes safety and data-protection guardrails.

This v0 is intentionally simple, fast to run locally, and designed to scale with open-source components.

## Key Features
- Retrieval-Augmented Generation (RAG) over a local markdown knowledge base
- Out-of-scope detection with friendly redirection
- Safety and privacy guardrails (PII redaction, non-diagnostic disclaimers)
- Optional user context (simple, pluggable per-user store)
- Open-source by default:
  - LLM via Ollama (Llama 3.1 or Mistral)
  - Embeddings via sentence-transformers
  - Vector search via FAISS
- Clean FastAPI service with a single `/chat` endpoint
- Simple ingestion pipeline for KB
- Clear path to scale to pgvector, vLLM, Langfuse, NeMo Guardrails/Presidio, etc.

## Quickstart

### 1) Prerequisites
- Python 3.10+
- pip
- Optional: [Ollama](https://ollama.ai) running locally (recommended)
  - Suggested model: `llama3.1:8b` or `mistral:7b`

### 2) Install
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

### 3) Configure
Copy `.env.example` to `.env` and edit as needed.
```bash
cp .env.example .env
```
By default, Finn will:
- Use Ollama at http://localhost:11434 with `llama3.1:8b`.
- Fall back to OpenAI if `OPENAI_API_KEY` is present (optional).
- Store embeddings and FAISS index locally under `.data/`.

### 4) Ingest Knowledge Base
```bash
python scripts/ingest_kb.py --kb_dir data/kb
```

### 5) Run the API
```bash
uvicorn app.main:app --reload
```
- Health check: `GET http://localhost:8000/health`
- Chat: `POST http://localhost:8000/chat`

Example:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "u123",
    "session_id": "s123",
    "message": "How much water should I drink daily?",
    "context_opt_in": true
  }'
```

Response:
```json
{
  "reply": "A general guideline is ...",
  "sources": [
    {"title":"Hydration Basics","source_id":"hydration.md"}
  ],
  "safety": {"pii_redacted": false, "blocked": false, "reason": ""},
  "out_of_scope": false
}
```

## Project Structure
```
.
├─ app/
│  ├─ main.py               # FastAPI app and routes
│  ├─ orchestrator.py       # Intent, RAG, prompting, assembly
│  ├─ retrieval.py          # Embeddings + FAISS + doc store
│  ├─ llm.py                # LLM and embedding wrappers (Ollama/OpenAI/HF)
│  ├─ safety.py             # PII redaction & basic safety checks
│  ├─ memory.py             # Minimal session memory store (SQLite)
│  ├─ config.py             # Pydantic settings
│  └─ models.py             # Pydantic request/response models
├─ prompts/
│  ├─ system.md
│  └─ rag.md
├─ data/
│  └─ kb/
│     ├─ wellness_basics.md
│     ├─ hydration.md
│     └─ sleep.md
├─ scripts/
│  └─ ingest_kb.py
├─ tests/
│  ├─ test_rag.py
│  └─ test_safety.py
├─ .env.example
├─ requirements.txt
├─ Dockerfile
└─ DESIGN.md
```

## Notes on Safety and UX
- Always includes non-diagnostic disclaimers for medical queries
- PII redaction for logs and outbound prompts (email, phone, SSN basic)
- Out-of-scope detection with friendly redirection to supported topics
- Context opt-in flag controls personalization (no default data mining)

## Scaling Path (Open-Source First)
- Model serving: vLLM for high-throughput inference; model routing via LiteLLM
- Vector store: pgvector on Postgres for multi-tenant + RBAC
- Guardrails: Presidio (PII), NeMo Guardrails or Guardrails.ai for policy flows
- Observability: OpenTelemetry + Prometheus; evals via RAGAS/DeepEval; tracing + feedback via Langfuse
- Personalization: feature-flagged user embeddings; privacy-first, opt-in
- Tool use: clinician handoff, appointment booking, wearable APIs (OAuth), sleep/steps import
- Security: JWT auth, encryption at rest (KMS), field-level encryption for sensitive data; DSR (export/delete)

## License
MIT (adjust as needed)