from typing import List, Dict
import os
import numpy as np

from app.config import Settings
from app.models import ChatRequest, ChatResponse, Safety, Source
from app.llm import LLM, Embeddings
from app.retrieval import VectorIndex, DocStore
from app.safety import redact_pii, safety_block
from app.memory import MemoryStore

def cosine_sim(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9))

class Orchestrator:
    def __init__(self, settings: Settings, memory: MemoryStore):
        self.settings = settings
        self.emb = Embeddings(settings.EMBED_MODEL)
        self.llm = LLM(
            use_ollama=settings.USE_OLLAMA,
            ollama_url=settings.OLLAMA_URL,
            ollama_model=settings.OLLAMA_MODEL,
            openai_key=settings.OPENAI_API_KEY,
            openai_model=settings.OPENAI_MODEL,
        )
        self.index = VectorIndex(settings.INDEX_DIR)
        self.index.load()
        self.docs = DocStore(settings.DOCS_PATH)
        self.domain_topics = [
            "sleep", "hydration", "nutrition", "movement", "stress management", "mindfulness", "habits", "recovery"
        ]

    def _detect_out_of_scope(self, q_vec: np.ndarray) -> bool:
        # Compare to KB vectors by proxy: if best FAISS score is low, we consider OOS.
        # FAISS returns inner product when index built as cosine; ingestion uses normalized vectors.
        results = self.index.search(q_vec, k=1)
        best_score = results[0][1] if results else -1.0
        return best_score < self.settings.OOS_THRESHOLD

    def _build_prompt(self, question: str, context_chunks: List[Dict[str, str]]) -> str:
        context_str = "\n\n".join([f"[{c['title']}] {c['text']}" for c in context_chunks])
        user_prompt = f"""You are Finn, a supportive wellness assistant. Use ONLY the context below to answer.
If the answer is not in the context, say you don't know and suggest where the user might look.
Be brief, practical, and cite sources by title in parentheses.

Context:
{context_str}

User question:
{question}

Answer:"""
        return user_prompt

    def _system_prompt(self) -> str:
        return """You are Finn, an AI wellness guide. Stay within general health & wellness.
Do not provide diagnosis or medical treatment. Encourage professional help when appropriate.
Be kind, concise, and evidence-informed. Cite sources with titles in parentheses. If unclear, ask a short clarifying question."""

    def handle_chat(self, req: ChatRequest) -> ChatResponse:
        # Safety pre-processing
        user_text = req.message
        was_redacted = False
        if self.settings.ENABLE_PII_REDACTION:
            user_text, was_redacted = redact_pii(user_text)
        blocked, reason = safety_block(user_text)
        if blocked:
            return ChatResponse(
                reply="I can’t assist with that. If you’re in immediate danger or crisis, please contact local emergency services or a trusted professional.",
                sources=[],
                safety=Safety(pii_redacted=was_redacted, blocked=True, reason=reason),
                out_of_scope=True
            )

        # Memory save user message
        # Note: consider hashing/anonymizing content in logs for privacy.
        # Short retention only in dev; production should implement retention policies.
        memory = self._get_memory()
        memory.add(req.user_id, req.session_id, "user", user_text)

        # Embeddings & OOS detection
        q_vec = self.emb.embed([user_text])
        q_vec = np.array(q_vec, dtype="float32")
        is_oos = self._detect_out_of_scope(q_vec)

        if is_oos:
            reply = ("I’m focused on wellness topics like sleep, hydration, nutrition, movement, and stress. "
                     "Could you rephrase your question within those areas? For example: “How can I improve my sleep quality?”")
            return ChatResponse(
                reply=reply,
                sources=[],
                safety=Safety(pii_redacted=was_redacted, blocked=False, reason=""),
                out_of_scope=True
            )

        # Retrieve context
        hits = self.index.search(q_vec, k=self.settings.TOP_K)
        chunks = []
        for doc_id, score in hits:
            doc = self.docs.get(doc_id)
            chunks.append({"title": doc.get("title", doc_id), "text": doc["text"], "id": doc_id})

        # Build prompt
        prompt = self._build_prompt(user_text, chunks)
        system = self._system_prompt()

        # Generate
        answer = self.llm.generate(prompt, system=system, max_tokens=512, temperature=0.2)

        # Add non-diagnostic disclaimer when relevant keywords appear
        if any(k in user_text.lower() for k in ["pain", "symptom", "diagnose", "treatment", "condition"]):
            answer += "\n\nNote: I can’t provide a medical diagnosis. For personalized medical advice, consult a licensed clinician."

        # Extract sources
        sources = []
        for ch in chunks:
            if ch["title"] not in [s.title for s in sources]:
                sources.append(Source(title=ch["title"], source_id=ch["id"]))

        # Save assistant message
        memory.add(req.user_id, req.session_id, "assistant", answer)

        return ChatResponse(
            reply=answer.strip(),
            sources=sources,
            safety=Safety(pii_redacted=was_redacted, blocked=False, reason=""),
            out_of_scope=False
        )

    def _get_memory(self) -> MemoryStore:
        return self.memory