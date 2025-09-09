import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.models import ChatRequest, ChatResponse
from app.config import Settings
from app.orchestrator import Orchestrator
from app.memory import MemoryStore

settings = Settings()
app = FastAPI(title="Finn - AI Wellness Bot v0", version="0.1.0")

# Allow simple local dev CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

memory = MemoryStore(db_path=settings.MEMORY_DB_PATH)
orchestrator = Orchestrator(settings=settings, memory=memory)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    try:
        result = orchestrator.handle_chat(req)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))