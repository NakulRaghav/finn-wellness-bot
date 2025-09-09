# Finn v0 Design & Scale Plan

## Goals
- Deliver a safe, helpful wellness assistant with minimal infrastructure
- Be privacy-first by design
- Build a composable foundation to scale features and performance

## Core Architecture (v0)
- API: FastAPI
- LLM: Ollama (llama3.1:8b or mistral:7b). Fallback: OpenAI (optional).
- Embeddings: sentence-transformers (all-MiniLM-L6-v2)
- Vector DB: FAISS local index
- KB Format: Markdown files with basic frontmatter (optional)
- Memory: SQLite-backed ephemeral session memory + optional summarization
- Guardrails:
  - PII redaction (regex-based; Presidio-ready)
  - Basic content filters (self-harm, violence, illegal, sexual minors) — block or redirect
  - Non-diagnostic disclaimer for medical topics
- Observability: structured logs; hooks for OpenTelemetry

### Request Flow
1. Receive message with `user_id`, `session_id`, `message`, `context_opt_in`.
2. Safety pre-check: redact PII in logs; block disallowed content if detected.
3. Intent/Scope detection:
   - Compute embedding for message; compare to KB centroids and domain keywords.
   - If low similarity, mark `out_of_scope` and return a friendly redirect.
4. If in-scope:
   - Retrieve top-K passages from FAISS.
   - Build prompt (system + RAG context + user).