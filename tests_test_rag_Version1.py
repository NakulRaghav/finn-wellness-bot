import os
import pytest
from app.config import Settings
from app.orchestrator import Orchestrator
from app.memory import MemoryStore
from app.models import ChatRequest

@pytest.mark.skipif(not os.path.exists(".data/index/faiss.index"), reason="Index not built")
def test_basic_retrieval():
    settings = Settings()
    orch = Orchestrator(settings, MemoryStore(settings.MEMORY_DB_PATH))
    req = ChatRequest(user_id="u1", session_id="s1", message="How much water should I drink daily?", context_opt_in=True)
    res = orch.handle_chat(req)
    assert res.reply
    assert any("hydration" in s.title.lower() for s in res.sources)
    assert not res.safety.blocked