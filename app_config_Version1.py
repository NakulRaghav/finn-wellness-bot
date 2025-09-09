import os
from pydantic import Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # LLM
    USE_OLLAMA: bool = True
    OLLAMA_MODEL: str = "llama3.1:8b"
    OLLAMA_URL: str = "http://localhost:11434"
    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"

    # Embeddings / Vector store
    EMBED_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    INDEX_DIR: str = ".data/index"
    DOCS_PATH: str = ".data/docs.jsonl"

    # Memory & Logs
    MEMORY_DB_PATH: str = ".data/state.db"
    LOG_PII: bool = False  # never log PII in prod

    # RAG params
    TOP_K: int = 4
    OOS_THRESHOLD: float = 0.28  # cosine similarity threshold for out-of-scope

    # Safety
    ENABLE_PII_REDACTION: bool = True
    ENABLE_SAFETY_FILTERS: bool = True

    class Config:
        env_file = ".env"