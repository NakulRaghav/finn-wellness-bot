from typing import List, Optional
from pydantic import BaseModel, Field

class ChatRequest(BaseModel):
    user_id: str = Field(..., description="Stable user id")
    session_id: str = Field(..., description="Stable session id")
    message: str = Field(..., description="User message")
    context_opt_in: bool = Field(default=True, description="Allow use of user context")

class Source(BaseModel):
    title: str
    source_id: str

class Safety(BaseModel):
    pii_redacted: bool
    blocked: bool
    reason: str = ""

class ChatResponse(BaseModel):
    reply: str
    sources: List[Source] = []
    safety: Safety
    out_of_scope: bool = False